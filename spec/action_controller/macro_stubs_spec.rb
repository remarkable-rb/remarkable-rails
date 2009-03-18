require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'MacroStubs' do
  controller_name 'tasks'

  def current_id; '37'; end

  it 'should create mocks methods dynamically' do
    self.instance_variable_get('@task').should be_nil
    self.respond_to?(:mock_task).should be_false

    mock_task

    self.instance_variable_get('@task').should_not be_nil
    self.respond_to?(:mock_task).should be_true
  end

  it 'should create procs which evals to mocks dynamically' do
    proc = self.class.mock_task
    proc.should be_kind_of(Proc)

    self.instance_variable_get('@task').should be_nil
    self.respond_to?(:mock_task).should be_false

    instance_eval &proc

    self.instance_variable_get('@task').should_not be_nil
    self.respond_to?(:mock_task).should be_true
  end

  describe :get => :show, :id => 37 do
    expects :find, :on => Task, :with => proc{ current_id }, :returns => mock_task

    it 'should run action declared in describe' do
      @controller.send(:performed?).should_not be_true

      run_action!(false)

      @controller.action_name.should == 'show'
      @controller.request.method.should == :get
      @controller.send(:performed?).should be_true
    end

    it 'should run action with expectations' do
      self.should_receive(:current_id).once.and_return('37')
      run_action!
      @controller.send(:performed?).should be_true
    end

    it 'should run expectations without performing an action' do
      self.should_receive(:current_id).once.and_return('37')
      run_expectations!
      @controller.send(:performed?).should_not be_true
      Task.find('37') # Execute expectations by hand
    end

    it 'should run action with stubs' do
      self.should_receive(:current_id).never
      run_action!(false)
      @controller.send(:performed?).should be_true
    end

    it 'should run stubs without performing an action' do
      self.should_receive(:current_id).never
      run_stubs!
      @controller.send(:performed?).should_not be_true
    end

    describe 'with mime type XML' do
      expects :to_xml, :on => mock_task, :returns => 'XML'
      mime Mime::XML

      it 'should run action based on inherited declarations' do
        @controller.send(:performed?).should_not be_true

        run_action!

        @controller.action_name.should == 'show'
        @controller.request.method.should == :get
        @controller.send(:performed?).should be_true
        @controller.response.body.should == 'XML'
      end
    end
  end

  describe 'responding with #DELETE destroy' do
    expects :find,    :on => Task,     :with => '37', :returns => mock_task
    expects :destroy, :on => mock_task

    delete :destroy, :id => 37

    it 'should run action declared in describe' do
      @controller.send(:performed?).should_not be_true

      run_action!

      @controller.action_name.should == 'destroy'
      @controller.request.method.should == :delete
      @controller.send(:performed?).should be_true
    end
  end

  describe :delete => :destroy, :id => 37 do
    expects :find,    :on => Task,     :with => '37', :returns => mock_task
    expects :destroy, :on => mock_task

    subject { controller }

    should_assign_to :task
    should_assign_to :task, :with => mock_task
    should_assign_to :task, :with_kind_of => Task

    should_set_the_flash
    should_set_the_flash :notice
    should_set_the_flash :notice, :to => 'Task deleted.'

    should_set_session
    should_set_session :last_action
    should_set_session :last_action, :to => [ 'tasks', 'destroy' ]

    should_redirect_to{ project_tasks_url(10) }
    should_redirect_to proc{ project_tasks_url(10) }, :with => 302
  end
end