module MonElec

  module Sender

    def self.send(msg = {})
        begin
          data = {
            values: { value: msg["value"] },
            timestamp: msg["timestamp"],
            tags: msg["tags"]
          }
          if MonElec.influxdb.write_point(msg["series"], data)
            MonElec.logger.info "MonElec::Sender - Inserted data : #{msg["series"]} : #{data.inspect}"
            return true
          else
            MonElec.logger.info "MonElec::Sender - Insert Failed : #{msg["series"]} : #{data.inspect}"
            return false
          end
        rescue Exception => e
          MonElec.logger.error "MonElec::Sender - Error inserting data : #{e.message}"
          return false
        end
      end

    def self.run!
      while message = MonElec.queue.pop
        MonElec.queue.commit if send(JSON.parse(message))
      end
    end

  end

end
