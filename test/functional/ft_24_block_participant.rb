
#
# testing ruote
#
# Tue Aug 11 13:56:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtBlockParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v0', :val => 'v0val'
        set :field => 'f0', :val => 'f0val'
        alpha
        bravo
        charly
      end
    end

    @engine.register_participant :alpha do
      @tracer << "a\n"
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "b:f0:#{workitem.fields['f0']}\n"
    end
    @engine.register_participant :charly do |workitem, fexp|
      @tracer << "c:f0:#{workitem.fields['f0']}:#{fexp.lookup_variable('v0')}\n"
    end

    #noisy

    assert_trace "a\nb:f0:f0val\nc:f0:f0val:v0val", pdef
  end

  TEST_BLOCK = Ruote.process_definition do
    sequence do
      alpha
      echo '${f:__result__}'
    end
  end

  def test_block_result

    return if Ruote::WIN or Ruote::JAVA
      # defective 'json' lib on windows render this test useless

    @engine.register_participant :alpha do |workitem|
      'seen'
    end

    #noisy

    assert_trace 'seen', TEST_BLOCK
  end

  def test_non_jsonfiable_result

    return if Ruote::WIN
      # defective 'json' lib on windows renders this test useless

    @engine.register_participant :alpha do |workitem|
      Time.now
    end

    #noisy

    match = if defined?(DataMapper) && DataMapper::VERSION < '1.0.0'
      /^$/
    elsif Ruote::JAVA
      /^$/
    else
      /\b#{Time.now.year}\b/
    end

    wfid = @engine.launch(TEST_BLOCK)

    @engine.wait_for(wfid)

    assert_match match, @tracer.to_s
  end

  def test_raise_security_error_before_evaluating_rogue_code

    fn = "test/bad.#{Time.now.to_f}.txt"

    @engine.participant_list = [
      #[ 'alpha', [ 'Ruote::BlockParticipant', { 'block' => 'exit(3)' } ] ]
      [ 'alpha', [ 'Ruote::BlockParticipant', { 'block' => "proc { File.open(\"#{fn}\", \"wb\") { |f| f.puts(\"bad\") } }" } ] ]
    ]

    #noisy

    wfid = @engine.launch(Ruote.define { alpha })

    @engine.wait_for(wfid)

    assert_equal false, File.exist?(fn), 'security check not enforced'

    assert_equal 1, @engine.errors(wfid).size
    assert_match /SecurityError/, @engine.errors(wfid).first.message

    FileUtils.rm(fn) rescue nil
  end
end
