# encoding: utf-8
module LdapSettingsHelper
  def config_css_classes(config)
    "ldap_setting #{config.active? ? 'enabled' : 'disabled' }"
  end

  def change_status_link(config)
    if config.active?
      link_to l(:button_disable), disable_ldap_setting_path(config), :method => :put, :class => 'icon icon-lock'
    else
      link_to l(:button_enable), enable_ldap_setting_path(config), :method => :put, :class => 'icon icon-unlock'
    end
  end

  def ldap_setting_tabs(form)
    [
      {:name => 'LdapSettings',          :partial => 'ldap_settings',          :label => :label_ldap_settings,          :form => form},
      {:name => 'SynchronizationActions',:partial => 'synchronization_actions', :label => :label_synchronization_actions, :form => form},
      {:name => 'Schedule',              :partial => 'schedule',                :label => :label_schedule,               :form => form},
      {:name => 'Test',                  :partial => 'test',                    :label => :label_test,                   :form => form}
    ]
  end

  def options_for_nested_groups
    [
      [l(:option_nested_groups_disabled), ''],
      [l(:option_nested_groups_on_parents), :on_parents],
      [l(:option_nested_groups_on_members), :on_members]
    ]
  end

  def options_for_group_membeship
    [
      [l(:option_group_membership_on_groups), :on_groups],
      [l(:option_group_membership_on_members), :on_members]
    ]
  end

  def options_for_dyngroups
    [
      [l(:option_dyngroups_disabled), ''],
      [l(:option_dyngroups_enabled), :enabled],
      [l(:option_dyngroups_enabled_with_ttl), :enabled_with_ttl]
    ]
  end

  def options_for_sync_on_login
    [
      [l(:option_sync_on_login_user_fields_and_groups), :user_fields_and_groups],
      [l(:option_sync_on_login_user_fields), :user_fields],
      [l(:option_sync_on_login_disabled), '']
    ]
  end

  def options_for_users_search_scope
    [
      [l(:option_users_search_subtree), :subtree],
      [l(:option_users_search_onelevel), :onelevel]
    ]
  end

  def options_for_schedule_frequency
    [
      [l(:option_schedule_every_15_min), 'every_15_min'],
      [l(:option_schedule_every_30_min), 'every_30_min'],
      [l(:option_schedule_hourly),       'hourly'],
      [l(:option_schedule_daily),        'daily']
    ]
  end

  def options_for_schedule_hour
    (0..23).map { |h| [format('%02d', h), h] }
  end

  def options_for_schedule_minute
    (0..59).map { |m| [format('%02d', m), m] }
  end

  def options_for_schedule_minute_full
    (0..59).map { |m| [format('%02d', m), m] }
  end

  def schedule_day_name(num)
    %w(Mon Tue Wed Thu Fri Sat Sun)[num - 1]
  end

  def group_fields
    has_group_ldap_attrs = @ldap_setting.has_group_ldap_attrs?

    GroupCustomField.all.map do |f|
      SyncField.new(
        f.id, f.name, f.is_required?,
        @ldap_setting.sync_group_fields? && @ldap_setting.group_fields_to_sync.include?(f.id.to_s),
        has_group_ldap_attrs ? @ldap_setting.group_ldap_attrs[f.id.to_s] : '',
        f.default_value
      )
    end
  end

  def user_fields
    has_user_ldap_attrs = @ldap_setting.has_user_ldap_attrs?

    (User::STANDARD_FIELDS + UserCustomField.all).map do |f|
      if f.is_a?(String)
        id       = f
        name     = l("field_#{f}")
        required = true
        ldap_attr = @ldap_setting.auth_source_ldap.send("attr_#{f}")
        default  = ''
      else
        id       = f.id
        name     = f.name
        required = f.is_required?
        ldap_attr = has_user_ldap_attrs ? @ldap_setting.user_ldap_attrs[id.to_s] : ''
        default  = f.default_value
      end
      sync = @ldap_setting.sync_user_fields? && @ldap_setting.user_fields_to_sync.include?(id.to_s)
      SyncField.new(id, name, required, sync, ldap_attr, default)
    end
  end

  def options_for_base_settings
    options = [[l(:option_custom), '']]
    options += base_settings.collect { |k, h| [h['name'], k] }.sort
    options_for_select(options, current_base)
  end

  def user_fields_list(fields, group_changes)
    text = fields.map { |(k, v)| "    #{user_field_name k} = #{v}\n" }.join
    groups = group_changes[:added].to_a.inspect
    text << "    #{l(:label_group_plural)} = #{groups}\n"
  end

  def group_fields_list(fields)
    return "    #{l(:label_no_fields)}\n" if fields.empty?
    fields.map { |(k, v)| "    #{group_field_name k} = #{v}\n" }.join
  end

  private

    def user_field_name(field)
      return l("field_#{field}") if field !~ /\A\d+\z/
      UserCustomField.find_by_id(field.to_i).name
    end

    def group_field_name(field)
      GroupCustomField.find_by_id(field.to_i).name
    end

    def baseable_fields
      LdapSetting::LDAP_ATTRIBUTES + LdapSetting::CLASS_NAMES + %w( group_membership nested_groups )
    end

    def current_base
      base_settings.each do |key, hash|
        return key if hash.slice(*baseable_fields).all? { |k, v| @ldap_setting.send(k) == (v || '') }
      end
      ''
    end

    def base_settings
      @base_settings if defined? @base_settings

      config_dir = File.join(Redmine::Plugin.find(:redmine_ldap_sync).directory, 'config')
      default = baseable_fields.inject({}) { |h, k| h[k] = ''; h }
      @base_settings = YAML::load_file(File.join(config_dir, 'base_settings.yml'))
      @base_settings.each { |k, h| h.reverse_merge!(default) }
    end

    class SyncField < Struct.new :id, :name, :required, :synchronize, :ldap_attribute, :default_value
      def synchronize?; synchronize; end
      def required?; required; end
    end
end
