print("Initializing Node")
gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.LOW)

cfg={}
cfg.ssid="ESP_NODE1"
cfg.pwd="espespesp"
wifi.ap.config(cfg)
wifi.setmode(wifi.STATIONAP)

--create a config listener server
sv=net.createServer(net.TCP, 30)

sv:listen(7059, function(c)
    c:on("receive", function(c, pl)
        print("Request Received=>"..pl)
        pl=string.gsub(pl, "%s", "")
        _, _, cmd, ssid, pwd = string.find(pl, "(.+)/(.+)/(.+)")
        if (cmd == nil or ssid == nil or pwd == nil) then
            c:send("INVALID REQUEST")
            return
        end    
        
        print(cmd)
        print("'"..ssid.."'")
        print("'"..pwd.."'")
        if cmd == "SET" and ssid ~= "" and pwd ~= ""  then
            print("SETTING UP STATION")
            wifi.sta.config(ssid, pwd)
            print("SET - OK")
            wifi.sta.connect()
            print("CONNECTING...")
            tmr.delay(10000000)
            print("WIFI STATUS"..wifi.sta.status())
            if wifi.sta.status() == 5 then
                c:send("NODE IP:"..wifi.sta.getip())
                print("CONNECTED TO: "..wifi.sta.getconfig())
            end
            if wifi.sta.status() == 3 then
                c:send("AP DOWN")
            end
            if wifi.sta.status() == 2 then
                c:send("WRONG CREDENTIAL")
            end
            if wifi.sta.status() == 1 then
                c:send("CONNECTING...")
            end
        else
            c:send("INVALID COMMAND")
        end
    end)
end)

wifi.sta.eventMonReg(wifi.STA_GOTIP, 
    function() 
        print("CONNECTED TO: "..wifi.sta.getconfig())
        print("TRYING TO CONNECT IOTPLAYGROUND MQTT")
    
        m = mqtt.Client("ESP_NODE1", 120, "arunwizz", "won528poe472")
        m:on("connect", function(client) print ("MQTT CONNECTED") end)
        m:on("offline", function(client) print ("MQTT DISCONNECTED") end)
    
        m:on("message", function(client, topic, data) 
            print(topic .. ":" ) 
            if data ~= nil then
                print(data)
            end
        end)
    
        m:connect("cloud.iot-playground.com", 
            1883, 
            0, 
            function(client) 
                print("MQTT CONNECTION SUCCESS") 
                m:subscribe("/2/ESP_NODE1",0, function(client) 
                    print("SUBSCRIBED TO TOPIC /2/ESP_NODE1")
                end)
            end, 
            function(client, reason) 
                print("MQTT CONNECTION FAILED: "..reason) 
            end
        )
    end)
wifi.sta.eventMonStart()
print("Initializing Node - OK")
