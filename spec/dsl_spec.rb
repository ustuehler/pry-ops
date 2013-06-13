require 'pry-ops/dsl_definition'

describe "PryOps DSL" do
  subject do
    obj = Object.new
    obj.send :extend, PryOps::DSL
    obj
  end

  context "context" do
    it "defines top-level name spaces" do
      subject.instance_eval do
        context :test do
          PryOps.application.current_scope.should == ['test']
        end
      end
    end

    it "defines nested name spaces" do
      subject.instance_eval do
        context :test do
          context "sub.context" do
            PryOps.application.current_scope.join('.').should == 
              'test.sub.context'
          end
        end
      end
    end
  end
end
