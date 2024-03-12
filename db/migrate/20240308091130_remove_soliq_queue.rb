class RemoveSoliqQueue < ActiveRecord::Migration[7.1]
  def change
    drop_table :solid_queue_jobs, force: :cascade
    drop_table :solid_queue_scheduled_executions, force: :cascade
    drop_table :solid_queue_ready_executions, force: :cascade
    drop_table :solid_queue_claimed_executions, force: :cascade
    drop_table :solid_queue_blocked_executions, force: :cascade
    drop_table :solid_queue_failed_executions, force: :cascade
    drop_table :solid_queue_pauses, force: :cascade
    drop_table :solid_queue_processes, force: :cascade
    drop_table :solid_queue_semaphores, force: :cascade
  end
end
