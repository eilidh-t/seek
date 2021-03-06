# top level abstract class for defining jobs
# that automatically handles performing the job, and and handling and reporting any errors.
# utility methods for counting and checking if a job exists, and creating a new job.
class SeekJob
  include CommonSweepers
  include DefaultJobProperties # the default properties - these are methods that can be overridden in the job implementation

  def perform
    gather_items.each do |item|
      begin
        Timeout.timeout(timelimit) do
          perform_job(item)
        end
      rescue Exception => exception
        report_exception(exception)
        retry_item(item)
      end
    end
    if follow_on_job?
      queue_job(follow_on_priority, follow_on_delay.from_now, true)
    end
  end

  #adds the job to the Delayed Job queue. Will not create it if it already exists and allow_duplicate is false,
  #or by default allow_duplicate_jobs? returns false.
  def queue_job(priority = default_priority, time = default_delay.from_now, allow_duplicate = allow_duplicate_jobs?)
    if allow_duplicate || !exists?
      Delayed::Job.enqueue(self, priority: priority, queue: queue_name, run_at: time)
    end
  end

  def exists?(ignore_locked = true)
    count(ignore_locked) != 0
  end

  def count(ignore_locked = true)
    if ignore_locked
      Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?', job_yaml, nil, nil]).count
    else
      Delayed::Job.where(['handler = ? AND failed_at IS ?', job_yaml, nil]).count
    end
  end

  private

  def job_yaml
    to_yaml
  end

  def gather_items
    []
  end

  def retry_item(_item)
    # by default doesn't retry
  end

  def report_exception(exception, message = nil, data = {})
    message ||= "Error executing job for #{self.class.name}"
    data[:message] = message
    if Seek::Config.exception_notification_enabled
      ExceptionNotifier.notify_exception(exception, data: data)
    end
    Rails.logger.error(exception)
  end

  def take_queued_item(queued)
    item = queued.item
    queued.destroy
    item
  end
end
