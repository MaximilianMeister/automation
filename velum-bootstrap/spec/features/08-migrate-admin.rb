require "spec_helper"
require 'yaml'

feature "Upgrade Admin Node" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"] if m["role"] != "admin" }.compact }

  before(:each) do
    login
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User clicks migrate admin node" do
    with_status_ok do
      visit "/"
    end

    puts ">>> Wait for migrate-admin-node button to be enabled"
    with_screenshot(name: :migrate_admin_node_button_enabled) do
      expect(page).to have_selector("a.migrate-admin-btn", wait: 400)
    end
    puts "<<< migrate-admin-node button enabled"

    puts ">>> Click to migrate admin node"
    with_screenshot(name: :migrate_admin_node_button_click) do
      find('a.migrate-admin-btn').click
    end
    puts ">>> migrate admin node clicked"

    puts ">>> Wait for reboot-admin-node button to be enabled"
    with_screenshot(name: :reboot_admin_node_button_enabled) do
      expect(page).to have_selector("button.reboot-update-btn", wait: 15)
    end
    puts "<<< reboot-admin-node button enabled"

    puts ">>> Click to reboot admin node"
    with_screenshot(name: :reboot_admin_node_button_click) do
      find('button.reboot-update-btn').click
    end
    puts ">>> reboot admin node clicked"

    puts ">>> Waiting 30 seconds to allow Velum to shutdown"
    sleep 30
    # make real busy loop, and fix it in 04 as well
    puts "<<< Waiting 30 seconds to allow Velum to shutdown"

    puts ">>> Wait for Velum to recover"
    1.upto(1200) do |n|
      begin
        with_status_ok do
          visit "/"
        end
        break
      rescue Exception => e
        if n == 600
          raise e
        else
          puts "... still waiting for velum to recover"
          sleep 1
        end
      end
    end
    puts "<<< Velum has recovered"

    # TODO: Salt is taking longer than expected to recover post-reboot, give it some
    # extra time.
    puts ">>> Waiting 60 seconds as a workaround"
    sleep 60
    puts "<<< Waiting 60 seconds as a workaround"
  end
end
