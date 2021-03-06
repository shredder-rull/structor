module Structor
  class Preloader
    class SingularAssociation < Association #:nodoc:
      private

      def preload(preloader)
        associated_records_by_owner(preloader).each do |owner, records|
          owner[reflection.name.to_s] = records.first
        end
      end
    end
  end
end