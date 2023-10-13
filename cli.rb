#require 'getoptlong'

opts = GetoptLong.new(
  [ '--vm', GetoptLong::REQUIRED_ARGUMENT]
)

opts.ordering=(GetoptLong::REQUIRE_ORDER)

vm=''

opts.each do |opt, arg|
  case opt
    when '--vm'
      unless arg == 'virtualbox' || arg == 'vmware'
        abort("На данный момент поддерживается только --vm=virtualbox и --vm==vmware")
      end
      vm=arg
  end
end
