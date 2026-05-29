# encoding: utf-8
module LdapSync
  class Hooks < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('ldap_sync.css', :plugin => 'redmine_ldap_sync') +
      javascript_include_tag('ldap_settings.js', :plugin => 'redmine_ldap_sync')
    end

    # Admin oldalon ellenőrizzük az ütemezett szinkronizációt
    def view_layouts_base_body_bottom(context = {})
      LdapSync::Scheduler.check_and_run_all rescue nil
      ''
    end

  end
end
