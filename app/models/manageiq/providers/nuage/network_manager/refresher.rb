module ManageIQ::Providers
  class Nuage::NetworkManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def parse_legacy_inventory(ems)
      ManageIQ::Providers::Nuage::NetworkManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end

    def post_process_refresh_classes
      []
    end

    def collect_inventory_for_targets(ems, targets)
      log_header = format_ems_for_logging(ems)
      targets_with_data = targets.collect do |target|
        target_name = target.try(:name) || target.try(:event_type)

        _log.info("#{log_header} Filtering inventory for #{target.class} [#{target_name}] id: [#{target.id}]...")

        if refresher_options.try(:[], :inventory_object_refresh)
          inventory = ManageIQ::Providers::Nuage::Builder.build_inventory(ems, target)
        end

        _log.info("#{log_header} Filtering inventory...Complete")
        [target, inventory]
      end

      targets_with_data
    end

    def parse_targeted_inventory(ems, _target, inventory)
      log_header = format_ems_for_logging(ems)
      _log.debug("#{log_header} Parsing inventory...")
      hashes, = Benchmark.realtime_block(:parse_inventory) do
        if refresher_options.try(:[], :inventory_object_refresh)
          inventory.inventory_collections
        else
          ManageIQ::Providers::Nuage::NetworkManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
        end
      end
      _log.debug("#{log_header} Parsing inventory...Complete")

      hashes
    end
  end
end
