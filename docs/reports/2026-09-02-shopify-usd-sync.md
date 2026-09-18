# Отчёт: синхронизация Shopify в USD и отказ от legacy-бэкфилла

Дата: 2026-09-02/03. Ветка: `174-expenses-analytics`. Спека (уже удалена после выполнения,
содержимое сохранено в git-истории): `.specs/174-expenses-analytics/20260902T140903Z__shopify-usd-sync-and-legacy-retirement/`.

Коммиты (в порядке выполнения):

```
c0182b881 feat(shopify): cache dated EUR-to-USD ECB rates
50dbf22d8 feat(shopify): store orders in USD via one order-level EUR conversion
9e9ddbdd0 test(shopify): prove USD conversion parity across sync entry points
b60f3ab98 fix(shopify): audit live Shopify sync, widen ECB rate precision, defer unresolved variants
cb891630d chore(shopify): delete the legacy USD backfill
a6a1cf820 chore(specs): remove completed shopify-usd-sync-and-legacy-retirement iteration
```

## 1. Проблема, которая решалась

Магазин на Shopify выставляет суммы заказов в `MoneyBag.shopMoney` — и для этого магазина это
**всегда EUR** (подтверждено живым аудитом 1300+ заказов). Старый код:

- Парсер (`Sale::Shopify::Parser`) конвертировал **каждое денежное поле по отдельности**, читая
  `shopMoney.currencyCode` из каждого JSON-узла и вызывая обобщённый метод конвертации отдельно для
  каждой суммы — то есть для одного заказа мог использоваться разный курс на разные поля, и сам курс
  нигде не сохранялся (невозможно было потом объяснить, откуда взялась сумма в USD).
- Помимо нормального пути синхронизации существовал **параллельный ручной механизм**
  `Sale::UsdBackfill` + rake-таска `backfill_sales_to_usd`, которые напрямую переписывали уже
  сохранённые суммы в БД — дублирующий, необслуживаемый путь записи денег.
- `ExchangeRate` (кеш курсов ЕЦБ) заполнял таблицу **только один раз** (если пустая) и никогда не
  обновлял её — при бесконечной работе сервиса кешould неограниченно устаревать.

Цель: сделать единственным источником истины обычную кнопку **Synchronize sales**, где один заказ
даёт один курс EUR→USD, курс и его дата сохраняются вместе с суммами, а legacy-бэкфилл удаляется.

## 2. Тикет 01 — дated-кеш курсов ЕЦБ

Файл: `app/models/exchange_rate.rb`.

### Что добавлено

**`ExchangeRate::Conversion`** — value-object (`Data.define`), который отдаёт вместе дату заказа,
дату публикации курса ЕЦБ, сам курс и умеет конвертировать суммы:

```ruby
Conversion = Data.define(:order_date, :effective_date, :rate) do
  def usd_amount(amount)
    (amount.to_d * rate).round(2)
  end
end

def self.eur_to_usd_conversion(date:)
  ensure_recent!

  effective_date, rate = where(currency: "USD").where(date: ..date).order(date: :desc).pick(:date, :rate)
  raise ArgumentError, "No ECB EUR-to-USD rate cached on or before #{date}" unless rate

  Conversion.new(order_date: date, effective_date:, rate:)
end
```

Важно: `eur_to_usd_conversion` **не** использует существующий `median_rate_for_missing_history`
(медианный фолбэк) — если курса на дату или раньше нет, метод падает с `ArgumentError`. Это
осознанное решение спеки: для Shopify лучше явная ошибка, чем угаданный курс.

### Обновление кеша: было "один раз", стало "не старше 24 часов"

```ruby
def self.ensure_cached!          # старое поведение, используется generic-путём (Seal/Woo)
  return if exists?
  refresh!(Ecb::ExchangeRatesClient.new.fetch_all)
end

def self.ensure_recent!          # новое поведение, используется только Shopify-конвертацией
  return ensure_cached! unless exists?
  return if maximum(:fetched_at) > REFRESH_INTERVAL.ago
  refresh!(Ecb::ExchangeRatesClient.new.fetch_recent)
end

def self.refresh!(rows)
  fetched_at = Time.current
  upsert_all(rows.map { |row| row.merge(fetched_at:) }, unique_by: %i[currency date])
end
```

**Почему два метода, а не один.** Первая версия была единой (`ensure_recent!` использовался и в
`rate_on`, который дергает Seal/Woo). Это сломало существующий тест
`spec/jobs/woo/pull_sales_job_spec.rb`, который делает `travel_to("2030-01-01")` — из-за
"путешествия во времени" кеш вдруг выглядел устаревшим и код пытался лезть в реальную сеть за ЕЦБ.
Решение: `rate_on` (Seal/Woo) остаётся на старом `ensure_cached!` (кеш заполняется один раз и
больше не трогается) — их поведение спека прямо требует не менять. Только новый Shopify-путь
(`eur_to_usd_conversion`) получил обновление раз в 24 часа.

### Новый клиент ЕЦБ: полная история + "свежая" лента

Файл: `app/services/ecb/exchange_rates_client.rb`.

```ruby
HISTORY_URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.xml"
RECENT_URL  = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml"

def fetch_all    = fetch(HISTORY_URL)
def fetch_recent = fetch(RECENT_URL)
```

`fetch_all` — вся история ЕЦБ (используется один раз при пустом кеше). `fetch_recent` — фид за
последние 90 дней (используется при обновлении раз в 24 часа; 90 дней — запас на случай, если
приложение не запускалось несколько дней подряд).

### Тесты

`spec/models/exchange_rate_spec.rb`, `spec/services/ecb/exchange_rates_client_spec.rb` — новые
кейсы: конвертация EUR→USD с датой и курсом, курс в выходной день (берётся ближайшая более ранняя
публикация), пустой/свежий/устаревший кеш, "успешное обновление без новой даты всё равно продлевает
свежесть", много конвертаций после одного обновления без новых HTTP-запросов, провал сети без
частичной записи в БД.

## 3. Тикет 02 — суммы Shopify хранятся в USD с одним курсом на заказ

### GraphQL-запрос: убрали построчный `currencyCode`, добавили заказный

Файл: `app/services/shopify/graphql/order_query.rb`.

Было — на каждую денежную сумму заказа запрашивался её собственный `currencyCode`:
```graphql
totalPriceSet {
  shopMoney { amount currencyCode }
}
```
Стало — валюта запрашивается **один раз на уровне заказа**, суммы — просто `amount`:
```graphql
createdAt
currencyCode
...
presentmentCurrencyCode
...
totalPriceSet {
  shopMoney { amount }
}
```
То же самое сделано для `totalDiscountsSet`, `totalShippingPriceSet`, `currentTotalPriceSet`,
`totalReceivedSet`, `totalOutstandingSet`, `netPaymentSet`, `totalRefundedSet`, строк заказа
(`originalTotalSet`, `discountedTotalSet`) и графика платежей Shopify (`balanceDue`, `totalBalance`).

### Парсер: один контекст конвертации на весь заказ

Файл: `app/models/sale/shopify/parser.rb`.

```ruby
def order_conversion
  return @order_conversion if defined?(@order_conversion)

  @order_conversion = shopify_created_at && ExchangeRate.eur_to_usd_conversion(date: shopify_created_at.to_date)
end

def converted_money(money_set)
  amount = money_set&.dig("shopMoney", "amount")
  return nil if amount.blank?

  order_conversion&.usd_amount(amount)
end

def currency_attributes
  return {shop_currency: nil, presentment_currency: nil, usd_conversion_rate: nil, exchange_rate_date: nil} unless order_conversion

  {
    shop_currency: @order["currencyCode"],
    presentment_currency: @order["presentmentCurrencyCode"],
    usd_conversion_rate: order_conversion.rate,
    exchange_rate_date: order_conversion.effective_date
  }
end
```

`order_conversion` вычисляется **один раз** (мемоизация через `defined?(@order_conversion)`) и
переиспользуется во всех местах: `discount_total`, `shipping_total`, `total`, `expected_revenue`,
`received_revenue`, `outstanding_revenue`, `refunded_revenue`, `net_payment`, цены и revenue по
строкам заказа, а также по суммам платёжного плана Shopify (`PaymentTerms`):

```ruby
projected_total: order_conversion&.usd_amount(raw_total),
...
amount: order_conversion&.usd_amount(schedule_total_balance(schedule)),
```

**Удалено** как обесценившееся: `schedule_currency` и `payment_plan_currency` — методы, которые
раньше вычисляли валюту графика платежей по полю `currencyCode` каждого элемента графика. Теперь
график платежей просто использует тот же самый `order_conversion`, что и всё остальное в заказе.

### Схема: 4 новых поля + ограничения

Миграция: `db/migrate/20260902150000_add_shopify_currency_fields_to_sales.rb`.

```ruby
add_column :sales, :shop_currency, :string
add_column :sales, :presentment_currency, :string
add_column :sales, :usd_conversion_rate, :decimal, precision: 18, scale: 10
add_column :sales, :exchange_rate_date, :date

add_check_constraint :sales,
  "(shop_currency IS NULL AND presentment_currency IS NULL AND usd_conversion_rate IS NULL AND exchange_rate_date IS NULL) " \
  "OR (shop_currency IS NOT NULL AND presentment_currency IS NOT NULL AND usd_conversion_rate IS NOT NULL AND exchange_rate_date IS NOT NULL)",
  name: "sales_currency_fields_all_or_none"

add_check_constraint :sales, "shop_currency IS NULL OR shop_currency ~ '^[A-Z]{3}$'", name: "sales_shop_currency_format"
add_check_constraint :sales, "presentment_currency IS NULL OR presentment_currency ~ '^[A-Z]{3}$'", name: "sales_presentment_currency_format"
add_check_constraint :sales, "usd_conversion_rate IS NULL OR usd_conversion_rate > 0", name: "sales_usd_conversion_rate_positive"
```

Все четыре поля — nullable, и на уровне БД гарантировано "все четыре или ни одного" — старые записи
могут спокойно оставаться пустыми до следующей синхронизации. Импортёр (`app/models/sale/shopify/importer.rb`)
кода для этого не потребовал: он и раньше брал `parsed[:sale].slice(*Sale.attribute_names...)`, так
что новые ключи из парсера подхватились автоматически.

### Тесты

`spec/models/sale_spec.rb` — новый блок "Shopify currency fields": полные данные, пустые данные,
частичные данные (падает по констрейнту `sales_currency_fields_all_or_none`), некорректный формат
кода валюты, неположительный курс.

`spec/models/sale/shopify/parser_spec.rb` — переписан блок бывшего "USD normalization" в "EUR to
USD conversion": один заказ с разными полями (скидка, доставка, revenue) — все конвертируются
**одним и тем же** курсом; отдельный тест на то, что `shop_currency`/`presentment_currency`/
`usd_conversion_rate`/`exchange_rate_date` сохраняются вместе.

`spec/models/sale/shopify/importer_spec.rb` — сохранение валютных полей, повторный импорт без
двойной конвертации, откат при сбое (валютные данные предыдущего успешного импорта не портятся).

## 4. Тикет 03 — доказательство, что путь синхронизации один

Код `app/jobs/shopify/base_pull_job.rb`, `pull_sales_job.rb`, `pull_sale_job.rb` уже был устроен
так, что и постраничная (`Shopify::PullSalesJob`), и одиночная (`Shopify::PullSaleJob`)
синхронизация проходят через один и тот же `Sale::Shopify::Parser`/`Sale::Shopify::Importer` — тут
ничего не пришлось переписывать. Тикет добавил тесты-доказательства в
`spec/jobs/shopify/pull_sales_job_spec.rb`:

- один и тот же "сырой" EUR-заказ, пропущенный через bulk-job и через single-order job, даёт
  **идентичные** `total`, `usd_conversion_rate`, `exchange_rate_date`;
- `limit:` влияет только на размер страницы запроса, не на конвертацию/сохранение;
- bulk-импорт, затем single-order импорт того же заказа — одна запись `Sale`, без дублей.

Заодно пришлось поправить старую фикстуру этого спека — после тикета 02 парсер всегда лезет за
курсом ЕЦБ, а старая фикстура не задавала `currencyCode`/дату курса, из-за чего тест пытался
реально сходить в сеть. Добавлена базовая ставка `create(:exchange_rate, date: Date.new(2000,1,1),
currency: "USD", rate: 1.0)` — по аналогии с уже существующим паттерном в
`spec/jobs/woo/pull_sales_job_spec.rb`.

## 5. Тикет 04 — реальный прогон синхронизации на живом магазине

Это была не автоматизация, а **операционная проверка**: нажать реальную кнопку "Synchronize sales"
без лимита на реально подключённом магазине (`68d8f5-af.myshopify.com`) и посмотреть, что
получится. По ходу вскрылись два реальных бага — оба исправлены и покрыты тестами.

### Баг 1 — курс ЕЦБ не помещался в колонку

Турецкая лира до деноминации 2005 года стоила **1 912 400** за 1 EUR (2004-12-09) — это больше, чем
может вместить `decimal(10,4)` (макс. 999 999.9999). При первой же реальной полной загрузке истории
ЕЦБ (`fetch_all`) Postgres упал с `PG::NumericValueOutOfRange`.

Исправление — `db/migrate/20260902160000_widen_exchange_rates_rate_precision.rb`:

```ruby
change_column :exchange_rates, :rate, :decimal, precision: 15, scale: 4
```

### Баг 2 — новый вариант товара ломал весь заказ целиком

Файл: `app/models/sale/shopify/sale_item_importer.rb`.

Запрос заказов специально **не тянет** список вариантов товара (чтобы не раздувать стоимость
GraphQL-запроса при постраничной синхронизации — см. тест "uses a lighter product payload for order
sync"). Если в заказе встречался вариант, которого ещё нет локально, а у товара не было
"базового"/дефолтного варианта-заглушки — валидация `VariantAssignment` падала с "Variant must be
selected", и весь заказ (внутри одной транзакции) откатывался целиком.

```ruby
def import!
  return if no_product_data?

  find_or_initialize_sale_item
  missing_product_reference = ...
  return create_title_only_sale_item! if only_product_title?
  return if unresolvable_new_variant?          # ← новая строка

  ActiveRecord::Base.transaction do
    sale_item.assign_attributes(sale_item_attributes)
    sale_item.save!
  end
  ...
end

# Заказный запрос никогда не тянет варианты (лёгкий запрос для постраничной синхронизации),
# поэтому неизвестный вариант нельзя разрешить здесь, а у мультивариантного товара нет
# запасного варианта. Откладываем на асинхронный подтяг товара; следующая полная
# синхронизация повторит эту строку заказа, когда вариант уже будет закеширован локально.
def unresolvable_new_variant?
  return false if parsed[:variant_store_id].blank?
  return false if Variant.find_by_shopify_id(parsed[:variant_store_id])
  return false if parsed.dig(:product, :variants).present?
  return false if resolved_product.blank?
  return false if resolved_product.assignable_variants.base_models.exists?

  Shopify::PullProductJob.perform_later(parsed[:product_store_id]) if parsed[:product_store_id].present?
  true
end
```

Это точная копия уже существующего паттерна "товара нет локально → отложить, подтянуть асинхронно"
(`Shopify::PullProductJob.perform_later(...) if missing_product_reference`), только для варианта.
Один заказ с такой строкой просто пропускается (без падения), а следующая полная синхронизация
доберёт вариант после того, как асинхронный подтяг товара его закеширует.

### Баг 3 (архитектурный, НЕ исправлен) — редирект рассрочки Seal теряет уже известный вариант

При живом прогоне обнаружилось, что 8 из 25 заказов в выборке падали не из-за бага 2, а по другой
причине: строки "Teilzahlung / Partial Payment" (частичная оплата через Seal) через
`Sale::InstallmentProductResolver` перенаправляются на **реальный** мультивариантный товар (пример:
"Nanami Kento" — 2 активных реальных варианта размера 1:1 и 1:2, плюс их generic-заглушка
деактивирована — так и должно быть, когда у товара уже есть настоящие варианты). Внешне тот же
симптом ("Variant must be selected" / "Variant must belong to the selected Product"), но причина не
в товаре и не в правиле "у товара минимум 1 вариант" (оно соблюдено), а в том, что
`Sale::Shopify::SaleItemImporter` при редиректе рассрочки жёстко обнуляет вариант, хотя нужная
информация уже есть:

```ruby
# app/models/sale/installment_product_resolver.rb — уже возвращает конкретную позицию
def origin_sale_item
  return nil if target_product.blank?

  SaleItem
    .non_installment
    .joins(:sale)
    .where(sales: {customer_id: sale.customer_id}, product_id: target_product.id)
    .order(:created_at)
    .first
end

# app/models/sale/shopify/sale_item_importer.rb — но её .variant никуда не переиспользуется
def imported_variant
  return @imported_variant if defined?(@imported_variant)
  return @imported_variant = nil if redirected_installment_product?   # ← вариант теряется здесь
  ...
```

`origin_sale_item` — это более ранняя настоящая покупка того же клиента этого же товара, и у неё
уже есть конкретный `.variant` (например, купленный размер 1:1). Именно поэтому автофолбэк
(`product.assignable_variants.base_models.first`) не может ничего подставить: у товара с двумя
реальными размерами и деактивированной заглушкой намеренно нет "безопасного" варианта по
умолчанию — но угадывать и не нужно, правильный вариант уже известен через `origin_sale_item`,
просто код его не читает. Это находится в домене Seal/рассрочек, который эта спека прямо исключает
("Do not change Seal parsing... payment-plan..."), поэтому чинить не стал — явно спросил
пользователя, и по его решению вместо фикса сделано следующее:

Файл: `app/jobs/shopify/pull_sales_job.rb`:

```ruby
def process_item(api_item)
  super
rescue Sale::Shopify::Importer::Error => e
  Rails.logger.error("Skipping Shopify order due to import failure: #{e.message}")
end
```

Такой же паттерн уже применялся в `app/jobs/shopify/pull_products_job.rb` для коллизий SKU — тут он
скопирован для Shopify-заказов: конкретный известный заказ логируется и пропускается, но **вся
остальная** страница и все следующие страницы истории продолжают синхронизироваться (раньше одна
такая ошибка обрывала весь job и останавливала пагинацию навсегда).

### Результат живого прогона

- 6 страниц по 250 заказов (максимум, который вообще разрешает Shopify GraphQL API — `first` больше
  250 отклоняется платформой, это не наш консервативный выбор);
- полная история ЕЦБ загружена один раз (220 484 строки, 41 валюта), при повторном прогоне —
  **ноль** дополнительных запросов к ЕЦБ (кеш свежий);
- **1286 из 1304** реальных заказов Shopify получили полные `shop_currency`,
  `presentment_currency`, `usd_conversion_rate`, `exchange_rate_date`, `settlement_status`;
- 18 заказов остались без данных — все 18 это баг 3 выше (задокументирован для отдельного тикета,
  не в рамках этой спеки);
- повторный запуск "Synchronize sales" дал **побайтово идентичные** агрегаты (число продаж, строк,
  платёжных планов, сумма всех `total` в USD, число заказов без валюты) — идемпотентность
  подтверждена;
- воспроизводимость проверена вручную: для старого заказа (2024-08-16, >1 года) и сегодняшнего —
  `raw_shopMoney_EUR × сохранённый_курс` совпадает с сохранённой суммой в USD день-в-день.

Полная доказательная база (счётчики, сэмплы, id заказов) сохранена в коммите `b60f3ab98` в файле
`.specs/.../artifacts/04-shopify-sync-audit.md` (сама спека потом удалена по правилам процесса —
содержимое доступно через `git show b60f3ab98:.specs/174-expenses-analytics/20260902T140903Z__shopify-usd-sync-and-legacy-retirement/artifacts/04-shopify-sync-audit.md`).

## 6. Тикет 05 — удаление legacy-бэкфилла

После того как обычная синхронизация доказала свою полноту, удалены:

- `app/models/sale/usd_backfill.rb` — класс, который напрямую переписывал суммы в БД в обход
  парсера/импортёра;
- `lib/tasks/backfill_sales_to_usd.rake` — ручная rake-таска поверх него (требовала
  `SHOPIFY_HISTORICAL_CURRENCY`);
- `spec/models/sale/usd_backfill_spec.rb` — тесты только этого класса.

Проверено (`rg -n "Sale::UsdBackfill|backfill_sales_to_usd|SHOPIFY_HISTORICAL_CURRENCY|payment_plan_currency|schedule_currency" app lib spec config docs`) — живых ссылок не осталось. Compatibility-шима,
заменяющей команды или "временного" пути специально не оставлено — чистый вырез.

## 7. Что осталось нетронутым (сознательно)

- Seal: парсинг, прогнозы, платёжные планы, атрибуция — не менялись (кроме случая, когда сам Seal
  вызывает `SalePaymentPlan.usd_amount`/`ExchangeRate.usd_amount` — этот generic-путь сохранён).
- WooCommerce: свой путь конвертации (`ExchangeRate.usd_amount`) не тронут.
- OAuth/Partner Dashboard scope `read_all_orders` — уже был включён, не менялся.

## 8. Открытый вопрос на будущее

Отдельным тикетом (вне этой спеки) стоит завести: `Sale::Shopify::SaleItemImporter#imported_variant`
при редиректе рассрочки (`redirected_installment_product?`) должен брать вариант из
`resolved_origin_sale_item&.variant` вместо жёсткого `nil` — эта информация уже вычисляется
`Sale::InstallmentProductResolver#origin_sale_item`, просто не используется. Список всех 18
известных затронутых заказов — в удалённом, но сохранённом в git артефакте (см. раздел 5).
