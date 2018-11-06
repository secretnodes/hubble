namespace :events do
  namespace :cosmos do

    task all: :environment do
      TaskLock.with_lock!( :cosmos, :events ) do
        puts "\nStarting task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.find_each do |chain|
          Cosmos::ValidatorEventsService.new(chain).run!
        end
        puts "Completed task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end

  end
end
