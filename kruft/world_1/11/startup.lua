local ok, err = pcall(function()
    shell.run("bank_monitor")
end)

if not ok then
    print("Reactor monitor crashed!")
    print(err)
    print("Rebooting in 10 seconds...")
    sleep(10)
    os.reboot()
end
