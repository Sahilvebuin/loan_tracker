namespace :emi do
  desc "Deduct EMI amounts from user accounts when schedule due dates have been reached (runs for Date.current)"
  task autopay: :environment do
    LoanEmiAutopayService.call
  end
end
