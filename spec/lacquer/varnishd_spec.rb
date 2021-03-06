require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe "Varnishd" do
  
  before do
    spec_root = Pathname.new(__FILE__).dirname.join('..').expand_path    
    Lacquer::Varnishd.stub!(:started_check_delay).and_return(0)
    Lacquer::Varnishd.stub!(:env).and_return('test')
    Lacquer::Varnishd.stub!(:root_path).and_return(spec_root)
  end
  
  def executes_with(regexp)
    new_method = Lacquer::Varnishd.method(:new)
    Lacquer::Varnishd.stub!(:new).and_return do |*args|
      varnishd = new_method.call(*args)
      varnishd.should_receive(:execute).with(regexp)
      varnishd.stub!(:log)
      varnishd
    end
  end
  
  it "passes settings in the initailizer" do
    Lacquer::Varnishd.new("listen" => ":80").listen.should == ":80"
  end
  
  it "loads settings from varnish_config" do
    Lacquer::Varnishd.config.should have_key("listen")
    Lacquer::Varnishd.config.should have_key("telnet")
    Lacquer::Varnishd.config.should have_key("sbin_path")
    Lacquer::Varnishd.config.should have_key("storage")
    Lacquer::Varnishd.config["params"].should have_key('overflow_max')
  end
  
  it "returns full path to varnishd" do
    executes_with(%r[/opt/varnishd/sbin/varnishd])
    Lacquer::Varnishd.new("sbin_path" => "/opt/varnishd/sbin").start
  end
  
  it "returns pid file" do
    executes_with(/log\/varnishd.test.pid/)
    Lacquer::Varnishd.new("sbin_path" => "/opt/varnishd/sbin").start
  end
  
  it "returns params as string" do
    Lacquer::Varnishd.new("params" => { "max" => 2000, "add" => 2 }).params_args.should == "-p max=2000 -p add=2"    
  end
  
  it "returns listen arg as string" do
    Lacquer::Varnishd.new("listen" => ":80").args.should include("-a :80")
  end
  
  it "starts varnishd with args and params" do
    executes_with(%r[/opt/varnishd/sbin.*-P.*log/varnishd.test.pid])
    Lacquer::Varnishd.new("sbin_path" => "/opt/varnishd/sbin", "params" => { "overflow_max" => 2000 }).start
  end
  
  it "raises error if vcl_script_file is not present" do
    Lacquer::Varnishd.stub!(:vcl_script_filename).and_return("config/file_not_found.vcl")
    expect {
      Lacquer::Varnishd.new.vcl_script_path
    }.to raise_error
  end
  
  it "renders vcl file when erb is present" do
    Lacquer::Varnishd.stub!(:vcl_script_filename).and_return("config/generate.vcl")
    result = Lacquer::Varnishd.new.render_vcl
    result.should include('.host = "0.0.0.0"')
    result.should include('.port = "3000"')
  end
  
end