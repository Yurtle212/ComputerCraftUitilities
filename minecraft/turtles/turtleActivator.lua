while true do
    os.pullEvent("peripheral")
    peripheral.find("turtle").turnOn()
    print("Activated")
end