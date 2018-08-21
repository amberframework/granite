require "../../spec_helper"

describe "#abort!" do
  context "when create" do
    it "doesn't run other callbacks if abort at before_save" do
      cwa = CallbackWithAbort.new(abort_at: "before_save", do_abort: true)
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at before_save."])
      cwa.history.to_s.strip.should eq("")
      CallbackWithAbort.find("before_save").should be_nil
    end

    it "only runs before_save if abort at before_create" do
      cwa = CallbackWithAbort.new(abort_at: "before_create", do_abort: true)
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at before_create."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        RUNS
      CallbackWithAbort.find("before_create").should be_nil
    end

    it "runs before_save, before_create and save successfully if abort at after_create" do
      cwa = CallbackWithAbort.new(abort_at: "after_create", do_abort: true)
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at after_create."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        before_create
        RUNS
      CallbackWithAbort.find("after_create").should be_a(CallbackWithAbort)
    end

    it "runs before_save, before_create, after_create and save successfully if abort at after_save" do
      cwa = CallbackWithAbort.new(abort_at: "after_save", do_abort: true)
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at after_save."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        before_create
        after_create
        RUNS
      CallbackWithAbort.find("after_save").should be_a(CallbackWithAbort)
    end
  end

  context "when update" do
    it "doesn't run other callbacks if abort at before_save" do
      CallbackWithAbort.new(abort_at: "before_save", do_abort: false).save
      cwa = CallbackWithAbort.find!("before_save")
      cwa.do_abort = true
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at before_save."])
      cwa.history.to_s.strip.should eq("")
      CallbackWithAbort.find!("before_save").do_abort.should be_false
    end

    it "only runs before_save if abort at before_update" do
      CallbackWithAbort.new(abort_at: "before_update", do_abort: false).save
      cwa = CallbackWithAbort.find!("before_update")
      cwa.do_abort = true
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at before_update."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        RUNS
      CallbackWithAbort.find!("before_update").do_abort.should be_false
    end

    it "runs before_save, before_update and save successfully if abort at after_update" do
      CallbackWithAbort.new(abort_at: "after_update", do_abort: false).save
      cwa = CallbackWithAbort.find!("after_update")
      cwa.do_abort = true
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at after_update."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        before_update
        RUNS
      CallbackWithAbort.find!("after_update").do_abort.should be_true
    end

    it "runs before_save, before_update, after_update and save successfully if abort at after_save" do
      CallbackWithAbort.new(abort_at: "after_save", do_abort: false).save
      cwa = CallbackWithAbort.find!("after_save")
      cwa.do_abort = true
      cwa.save

      cwa.errors.map(&.to_s).should eq(["Aborted at after_save."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_save
        before_update
        after_update
        RUNS
      CallbackWithAbort.find!("after_save").do_abort.should be_true
    end
  end

  context "when destroy" do
    it "doesn't run other callbacks if abort at before_destroy" do
      CallbackWithAbort.new(abort_at: "before_destroy", do_abort: true).save
      cwa = CallbackWithAbort.find!("before_destroy")
      cwa.destroy

      cwa.errors.map(&.to_s).should eq(["Aborted at before_destroy."])
      cwa.history.to_s.strip.should eq("")
      CallbackWithAbort.find("before_destroy").should be_a(CallbackWithAbort)
    end

    it "runs before_destroy and destroy successfully if abort at after_destory" do
      CallbackWithAbort.new(abort_at: "after_destroy", do_abort: true).save
      cwa = CallbackWithAbort.find!("after_destroy")
      cwa.destroy

      cwa.errors.map(&.to_s).should eq(["Aborted at after_destroy."])
      cwa.history.to_s.strip.should eq <<-RUNS
        before_destroy
        RUNS
      CallbackWithAbort.find("after_destroy").should be_nil
    end
  end
end
