klasses = [
  # Array,
  # Class,
  # Complex,
  # Dir,
  # Enumerable,
  # Enumerator,
  # Exception,
  # Hash,
  # Kernel,
  # Math,
  # Method,
  # Module,
  # Object,
  # Proc,
  # Range,
  # Rational,
  # Regexp,
  # Struct,
  String,
#  Time
]

%x{
  function getOptimizationStatus(fn) {
      switch(%GetOptimizationStatus(fn)) {
          case 1: return "optimized"; break;
          case 2: return "not optimized"; break;
          case 3: return "always optimized"; break;
          case 4: return "never optimized"; break;
          case 6: return "maybe deoptimized"; break;
      }
  }
  
  function triggerOptAndGetStatus(fn) {
    // using try/catch to avoid having to call functions properly
    try {
      // Fill type-info
      fn();
      // 2 calls are needed to go from uninitialized -> pre-monomorphic -> monomorphic
      fn();
    }
    catch (e) {}
    %OptimizeFunctionOnNextCall(fn);
    try {
      fn();
    }
    catch (e) {}
    return getOptimizationStatus(fn);
  }
}

# TODO: Create a text based report like in benchmarking.rake
# Add class methods as well as instance methods
# Need to instantiate an object to test?? Didn't seem to make a difference with String#index or String#gsub

optimization_status = Hash[klasses.map do |klass|
  methods = klass.instance_methods
  opt_status = Hash[methods.map do |method|
    method_func = `#{klass.instance_method(method)}.method`
    [method, `triggerOptAndGetStatus(#{method_func})`]
  end]
  by_status_grouped = opt_status.group_by {|method, status| status }
  as_hash = Hash[by_status_grouped.map do |status, stuff|
    list = stuff.map {|val| val[0]}
    [status, list]
  end]
  [klass, as_hash]
end]

puts '----Report----'
optimization_status.sort_by {|klass,_| klass}.each do |klass, statuses|
  puts "Class #{klass}"
  puts '--------------'
  statuses.sort_by {|stat,_| stat }.each do |status, methods|
    puts " Status: #{status}"
    puts "  Methods:"
    methods.sort.each do |m|
      puts "   #{m}"
    end
  end
end

puts 'done!'
