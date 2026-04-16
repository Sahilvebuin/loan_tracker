class LoanEmiAutopayJob < ApplicationJob
  queue_as :default

  def perform(as_of = nil)
    day =
      case as_of
      when Date then as_of
      when Time then as_of.to_date
      when String then Date.parse(as_of)
      else
        Date.current
      end
    LoanEmiAutopayService.call(as_of: day)
  end
end
