# frozen_string_literal: true

require_relative "../spec_helper"

unless HTTPInstrumentation.force_prepend?
  describe HTTPInstrumentation::Instrumentation do
    class TestClassBase
      attr_reader :trace

      def initialize
        @trace = []
      end
    end

    module TestPrepend
      def request(*args)
        @trace << :prepend
        super
      end
    end

    module TestAlias
      class << self
        def included(klass)
          klass.alias_method(:request_without_alias, :request)
          klass.alias_method(:request, :request_with_alias)
        end
      end

      def request_with_alias(*args)
        @trace << :alias
        request_without_alias(*args)
      end
    end

    module TestInstrumentation
      class << self
        attr_accessor :aliased
      end

      def request(*args)
        @trace << :instrumented
        if TestInstrumentation.aliased
          request_without_http_instrumentation(*args)
        else
          super
        end
      end
    end

    module TestInstrumentationPrepend
      class << self
        attr_accessor :aliased
      end

      def request(*args)
        @trace << :instrumented
        if TestInstrumentationPrepend.aliased
          request_without_http_instrumentation(*args)
        else
          super
        end
      end
    end

    describe "instrumenting class with methods already prepended" do
      class TestClass1 < TestClassBase
        def request(argument)
          @trace << argument
        end
      end
      TestClass1.prepend(TestPrepend)
      TestClass1.prepend(TestInstrumentationPrepend)
      HTTPInstrumentation::Instrumentation.instrument!(TestClass1, TestInstrumentationPrepend, :request)

      it "calls all methods in the chain" do
        instance = TestClass1.new
        instance.request(:test)
        expect(instance.trace).to eq([:instrumented, :prepend, :test])
      end
    end

    describe "instrumenting class with methods already aliased" do
      class TestClass2 < TestClassBase
        def request(argument)
          @trace << argument
        end
      end
      TestClass2.include(TestAlias)
      HTTPInstrumentation::Instrumentation.instrument!(TestClass2, TestInstrumentation, :request)

      it "calls all methods in the chain" do
        instance = TestClass2.new
        instance.request(:test)
        expect(instance.trace).to eq([:instrumented, :alias, :test])
      end
    end

    describe "aliasing methods that have already been instrumented" do
      class TestClass3 < TestClassBase
        def request(argument)
          @trace << argument
        end
      end
      HTTPInstrumentation::Instrumentation.instrument!(TestClass3, TestInstrumentation, :request)
      TestClass3.include(TestAlias)

      it "calls all methods in the chain" do
        instance = TestClass3.new
        instance.request(:test)
        expect(instance.trace).to eq([:alias, :instrumented, :test])
      end
    end

    describe "prepending methods that have already been instrumented" do
      class TestClass4 < TestClassBase
        def request(argument)
          @trace << argument
        end
      end
      HTTPInstrumentation::Instrumentation.instrument!(TestClass4, TestInstrumentation, :request)
      TestClass4.prepend(TestPrepend)

      it "calls all methods in the chain" do
        instance = TestClass4.new
        instance.request(:test)
        expect(instance.trace).to eq([:prepend, :instrumented, :test])
      end
    end

    describe "instrumenting a class more than once" do
      module TestInstrumentationTwice
        class << self
          attr_accessor :aliased
        end

        def request(*args)
          @trace << :instrumented
          if TestInstrumentationTwice.aliased
            request_without_http_instrumentation(*args)
          else
            super
          end
        end
      end

      class TestClass5 < TestClassBase
        def request(argument)
          @trace << argument
        end
      end

      it "does not install the instrumentation twice" do
        HTTPInstrumentation::Instrumentation.instrument!(TestClass5, TestInstrumentationTwice, :request)
        HTTPInstrumentation::Instrumentation.instrument!(TestClass5, TestInstrumentationTwice, :request)

        instance = TestClass5.new
        instance.request(:test)
        expect(instance.trace).to eq([:instrumented, :test])
      end
    end

    describe "instrumenting a class whose methods are defined in an included module" do
      module TestInstrumentationIncluded
        class << self
          attr_accessor :aliased
        end

        def request(*args)
          @trace << :instrumented
          if TestInstrumentationIncluded.aliased
            request_without_http_instrumentation(*args)
          else
            super
          end
        end
      end

      module TestIncludedMethods
        def request(argument)
          @trace << argument
        end
      end

      class TestClass6 < TestClassBase
        include TestIncludedMethods
      end

      # Aliasing would capture the instrumented method itself since including the
      # instrumentation module inserts it ahead of the module defining the method,
      # so the prepend strategy must be used.
      it "uses the prepend strategy to avoid infinite recursion" do
        HTTPInstrumentation::Instrumentation.instrument!(TestClass6, TestInstrumentationIncluded, :request)
        expect(TestInstrumentationIncluded.aliased).to be false

        instance = TestClass6.new
        instance.request(:test)
        expect(instance.trace).to eq([:instrumented, :test])
      end
    end
  end
end
