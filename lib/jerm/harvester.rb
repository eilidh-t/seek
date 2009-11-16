# To change this template, choose Tools | Templates
# and open the template in the editor.
module Jerm
  class Harvester
  
    attr_reader :base_uri

    def update
      items = changed_since(last_run)
      items.each do |item|
        resource = construct_resource(item)
        populate resource
      end
    end

    def last_run
      DateTime.parse("1 Jan 2007")
    end

    def populate resource
      resource.populate    
      puts resource.to_s    
    end

  end
end