module MonElec

  module Collector

    def self.run!
      track_value = 0
      loop do
        line = `#{MonElec.configuration[:collector][:command]}`
        match = line.match(/^(?<code>[A-Z]\d)\s.*Curr\s(?<value>\d+\.\d+)A/)
        if match && match[:code] && match[:value]
          if series = MonElec.configuration[:var_map][match[:code]]
            value = match[:value].send(series[:value_transform])
            if value != track_value
              if series[:min] && value < series[:min]
                MonElec.logger.warn "MonElec::Collector - Value below series minimum - #{series[:name]} : Value: #{value} : Min: #{series[:min]}"
              elsif series[:max] && value > series[:max]
                MonElec.logger.warn "MonElec::Collector - Value above series maximum - #{series[:name]} : Value #{value} : Max : #{series[:max]}"
              else
                track_value = value
                message = {
                  timestamp: Time.now.utc.to_i,
                  series: series[:name],
                  value: value,
                  tags: {
                    meter_id: match[:code]
                  }
                }
                MonElec.queue << message.to_json
                MonElec.logger.debug "MonElec::Collector - Queue Length: #{MonElec.queue.length}"
              end
            else
              MonElec.logger.debug "MonElec::Collector - Value not changed - #{series[:name]} : Value #{value} : Track : #{track_value}"
            end
          end
        end
        sleep MonElec.configuration[:collector][:cycle_time] || 3
      end
    end

  end

end
