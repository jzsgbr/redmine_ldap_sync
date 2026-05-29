# encoding: utf-8
require 'net/ldap'

class Net::LDAP
  class Entry
    include Enumerable

    # Enumerable-hez szükséges each metódus
    # Net::LDAP::Entry belső tárolója: @myhash (attr_symbol => [values])
    def each(&block)
      @myhash.each(&block)
    end
  end
end
