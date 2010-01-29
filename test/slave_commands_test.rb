require File.expand_path("teststrap", File.dirname(__FILE__))

context "MPlayer::Player" do
  setup do
    mock(Open4).popen4("/usr/bin/mplayer -slave -quiet test/test.mp3") { [true,true,true,true] }
    stub(true).gets { "playback" }
    @player = MPlayer::Slave.new('test/test.mp3')
  end
  
  context "pause" do
    setup { mock_stdin @player, "pause" }
    asserts("returns true") { @player.pause }
  end

  context "quit" do
    setup { mock_stdin @player, "quit" }
    asserts("returns true") { mock_stdin @player, "quit" }
  end

  context "volume" do

    context "increases" do
      setup { mock_stdin @player, "volume 1" }
      asserts("returns true") { @player.volume :up }
    end

    context "decreases" do
      setup { mock_stdin @player, "volume 0" }
      asserts("returns true") { @player.volume :down }
    end

    context "sets volume" do
      setup { mock_stdin @player, "volume 40 1" }
      asserts("returns true") { @player.volume :set,40 }
    end

    context "incorrect action" do
      setup { @player.volume :boo }
      asserts("returns false").equals false
    end
  end

  context "seek" do

    context "by relative" do
      setup { 2.times { mock_stdin @player, "seek 5 0" } }
      asserts("seek 5") { @player.seek 5 }
      asserts("seek 5,:relative") { @player.seek 5,:relative }
    end

    context "by percentage" do
      setup { mock_stdin @player, "seek 5 1" }
      asserts("seek 5,:percent") { @player.seek 5,:percent }
    end

    context "by absolute" do
      setup { mock_stdin @player, "seek 5 2" }
      asserts("seek 5,:absolute") { @player.seek 5,:absolute }
    end
  end

  context "edl_mark" do
    setup { mock_stdin @player, "edl_mark"}
    asserts("returns true") { @player.edl_mark }
  end
  
  context "speed_incr" do
    setup { mock_stdin @player, "speed_incr 5" }
    asserts("speed_incr 5") { @player.speed_incr 5 }
  end

  context "speed_mult" do
    setup { mock_stdin @player, "speed_mult 5" }
    asserts("speed_mult 5") { @player.speed_mult 5 }
  end

  context "speed_set" do
    setup { mock_stdin @player, "speed_set 5" }
    asserts("speed_set 5") { @player.speed_set 5 }
  end

  context "speed" do

    context "increment" do
      setup { mock(@player).speed_incr(5) { true } }
      asserts("speed 5,:increment") { @player.speed 5,:increment }
    end

    context "multiply" do
      setup { mock(@player).speed_mult(5) { true } }
      asserts("speed 5,:multiply") { @player.speed 5,:multiply }
    end

    context "set" do
      setup { 2.times { mock(@player).speed_set(5) { true } } }
      asserts("speed 5") {  @player.speed 5 }
      asserts("speed 5, :set") {  @player.speed 5,:set }
    end
  end

  context "frame_step" do
    setup { mock_stdin @player, "frame_step" }
    asserts("returns true") { @player.frame_step }
  end

  context "pt_step" do

    context "forced" do
      setup { mock_stdin @player, "pt_step 5 1"}
      asserts("pt_step 5, :force") { @player.pt_step 5, :force }
    end

    context "not forced" do
      setup { 2.times { mock_stdin @player, "pt_step 5 0" } }
      asserts("pt_step 5") {  @player.pt_step 5 }
      asserts("pt_step 5, :no_force") { @player.pt_step 5, :no_force }
    end
  end

  context "pt_up_step" do

    context "forced" do
      setup { mock_stdin @player, "pt_up_step 5 1"}
      asserts("pt_up_step 5, :force") { @player.pt_up_step 5, :force }
    end

    context "not forced" do
      setup { 2.times { mock_stdin @player, "pt_up_step 5 0" } }
      asserts("pt_up_step 5") {  @player.pt_up_step 5 }
      asserts("pt_up_step 5, :no_force") { @player.pt_up_step 5, :no_force }
    end
  end

  context "alt_src_step" do
    setup { mock_stdin @player, "alt_src_step 5" }
    asserts("returns true") { @player.alt_src_step 5 }
  end

  context "loop" do

    context "none" do
      setup { mock_stdin @player,"loop -1" }
      asserts("loop :none") { @player.loop :none }
    end

    context "forever" do
      setup { 2.times { mock_stdin @player, "loop 0" } }
      asserts("loop") { @player.loop }
      asserts("loop :forever") { @player.loop :forever }
    end

    context "set value" do
      setup { mock_stdin @player,"loop 5" }
      asserts("loop :set, 5") { @player.loop :set, 5 }
    end
  end
  
  context "use_master" do
    setup { mock_stdin @player, "use_master" }
    asserts("returns true") { @player.use_master }
  end

  context "mute" do

    context "toggle" do
      setup { mock_stdin @player, "mute"}
      asserts("returns true") { @player.mute }
    end

    context "set on" do
      setup { mock_stdin @player, "mute 1"}
      asserts("mute :on") { @player.mute :on }
    end

    context "set off" do
      setup { mock_stdin @player, "mute 0"}
      asserts("mute :off") { @player.mute :off }
    end
  end
  
  context "get" do

    %w[time_pos time_length file_name video_codec video_bitrate video_resolution
      audio_codec audio_bitrate audio_samples meta_title meta_artist meta_album
    meta_year meta_comment meta_track meta_genre].each do |info|
      context info do
        setup { mock_stdin @player, "get_#{info}" }
        asserts("get :#{info}") { @player.get info.to_sym }
      end
    end
  end

  context "load_file" do

    asserts("invalid file") { @player.load_file 'booger' }.raises ArgumentError,"Invalid File"
    context "append" do
      setup { mock_stdin @player, "loadfile test/test.mp3 1" }
      asserts("load_file test/test.mp3, :append") { @player.load_file 'test/test.mp3', :append }
    end

    context "no append" do
      setup { 2.times { mock_stdin @player, "loadfile test/test.mp3 0" } }
      asserts("load_file test/test.mp3") { @player.load_file 'test/test.mp3' }
      asserts("load_file test/test.mp3, :no_append") { @player.load_file 'test/test.mp3', :no_append }
    end
  end

  context "load_list" do

    asserts("invalid playlist") { @player.load_list 'booger' }.raises ArgumentError,"Invalid File"
    context "append" do
      setup { mock_stdin @player, "loadlist test/test.mp3 1" }
      asserts("load_list test/test.mp3, :append") { @player.load_list 'test/test.mp3', :append }
    end

    context "no append" do
      setup { 2.times { mock_stdin @player, "loadlist test/test.mp3 0" } }
      asserts("load_list test/test.mp3") { @player.load_list 'test/test.mp3' }
      asserts("load_list test/test.mp3, :no_append") { @player.load_list 'test/test.mp3', :no_append }
    end
  end
  
  
end