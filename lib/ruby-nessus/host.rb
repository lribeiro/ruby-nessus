module Nessus
  class Host
    attr_reader :host

    def initialize(host)
      @host = host
    end

    def hostname
      @hostname ||= @host.at('HostName').inner_text
    end

    def scan_start_time
      @host_scan_time = @host.at('startTime').inner_text
    end

    def scan_stop_time
      @host_scan_time = @host.at('stopTime').inner_text
    end
    
    def scan_run_time
      # Example: Fri Apr  3 23:36:54 2009
      if scan_start_time.empty? | scan_stop_time.empty?; return "N/A"; end
      h = ("#{Time.parse(scan_stop_time).strftime('%H').to_i - Time.parse(scan_start_time).strftime('%H').to_i}").gsub('-', '')
      m = ("#{Time.parse(scan_stop_time).strftime('%M').to_i - Time.parse(scan_start_time).strftime('%M').to_i}").gsub('-', '')
      s = ("#{Time.parse(scan_stop_time).strftime('%S').to_i - Time.parse(scan_start_time).strftime('%S').to_i}").gsub('-', '')
      return "#{h} hours #{m} minutes and #{s} seconds"
    end

    def netbios_name
      @netbios_name ||= @host.at('netbios_name').inner_text
    end

    def mac_addr
      @mac_addr ||= @host.at('mac_addr').inner_text
    end

    def dns_name
      @dns_name ||= @host.at('dns_name').inner_text
    end

    def os_name
      @os_name ||= @host.at('os_name').inner_text
    end

    def scanned_ports
      @scanned_ports ||= false_if_zero(
        @host.at('num_ports').inner_text.to_i
      )
    end

    def informational_events
      @informational_events ||= @informational_events ||= @host.at('num_lo').inner_text.to_i
    end

    def low_severity_events
      @low_severity_events ||= @host.at('num_lo').inner_text.to_i
    end

    def medium_severity_events
      @medium_severity_events ||= @host.at('num_med').inner_text.to_i
    end

    def high_severity_events(&block)
      unless @high_severity_events
        @high_severity_events = []

        @host.xpath("//ReportItem").each do |event|
          next if event.at('severity').inner_text.to_i != 3
          @high_severity_events << Event.new(event)
        end

        @high_severity_count = @host.at('num_hi').inner_text.to_i
      end

      @high_severity_events.each(&block)
      return @high_severity_count
    end

    def event_count
      (informational_events + low_severity_events + medium_severity_events + high_severity_events).to_i
    end

    def events(&block)
      events = {}
      @host.xpath("//ReportItem").each do |event|
        events[:port] = event.at('port').inner_text
        events[:severity] = event.at('severity').inner_text.to_i
        events[:pluginID] = event.at('pluginID').inner_text.to_i
        events[:pluginName] = event.at('pluginName').inner_text
        events[:data] = event.at('data').inner_text unless event.at('data').nil?
        block.call(Event.new(event)) if block
      end
      events
    end

  end
end