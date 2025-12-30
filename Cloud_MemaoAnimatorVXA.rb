#==============================================================================
# CloudTheWolf - Memao Animator VX Ace
#------------------------------------------------------------------------------
# Backport of: Cloud_MemaoAnimatorMZ (Ver 1.2)
# Engine: RPG Maker VX Ace (RGSS3)
#------------------------------------------------------------------------------
# PURPOSE
#------------------------------------------------------------------------------
# Provides full Memao-style character animation support for VX Ace using
# large (e.g. 48x48) sprite cells, multi-row animation maps, manual actions,
# run/walk/idle blending, and RGSS3-safe movement locking.
#
#------------------------------------------------------------------------------
# CHARSET TRIGGER
#------------------------------------------------------------------------------
# Any character graphic whose filename ends with:
#
#   _$(memao)
#
# Examples:
#   teo_$(memao).png
#   $teo_$(memao).png
#   !teo_$(memao).png
#
#------------------------------------------------------------------------------
# SPRITE ANCHORING (IMPORTANT)
#------------------------------------------------------------------------------
# Memao frames are larger than VX Ace’s default 32x32.
# This script correctly re-anchors sprites so the character’s FEET align
# with the tile they are standing on:
#
#   ox = CELL_WIDTH / 2
#   oy = CELL_HEIGHT
#
# If your debug tile is correct, but the sprite looks “too high”, this script
# already compensates for that.
#
#------------------------------------------------------------------------------
# SCRIPT CALLS (VX ACE STYLE)
#------------------------------------------------------------------------------
# Play a manual action (movement locked while playing):
#
#
#   Player
#   CloudMemao.play_action(:player, :pickup)
#
#   Events   
#
#   THIS EVENT
#   ev = $game_map.events[@event_id]
#   CloudMemao.play_action(:this_event, :pickup, :current, false, 0, self)
#
#   SPECIFIC EVENT
#   ev = $game_map.events[2]
#   CloudMemao.play_action(:event_id, :pickup, :current, false, 2, self)
#
# Stop a looping manual action:
#
#   CloudMemao.stop_action(:player)
#
#------------------------------------------------------------------------------
# WAITING FOR ACTIONS (RGSS3-CORRECT)
#------------------------------------------------------------------------------
# VX Ace does NOT support MV/MZ-style wait modes.
# To wait until a Memao action finishes, use:
#
#   CloudMemao.play_action(:player, :axe_chop)
#   wait_for_memao($game_player)
#
# Or for events:
#
#   ev = $game_map.events[@event_id]
#   CloudMemao.play_action(ev, :water)
#   wait_for_memao(ev)
#
#==============================================================================


module CloudMemao
  CELL_W       = 48
  CELL_H       = 48
  SCALE_PCT    = 150     # 200 = 2.0x
  CRISP_PIXELS = true    # rounds sprite x/y
  X_OFFSET     = 0
  Y_OFFSET     = 5       # applied with scale
  WALK_FPS     = 7
  IDLE_FPS     = 3
  RUN_FPS      = 9
  ACTION_FPS   = 8

  WALK_HOLD_FRAMES = 6   # holds "moving" state briefly to avoid idle flicker

  # Optional override (Ruby hash same shape as DEFAULT_ROW_MAP)
  ROW_MAP_OVERRIDE = nil

  # -----------------------------
  # Default Row Map (ported)
  # -----------------------------
  DEFAULT_ROW_MAP = {
    :rows => [
      { :r => 1,  :entries => [
        { :name => "idleDown",  :start => 1, :end => 4 },
        { :name => "idleUp",    :start => 5, :end => 8 },
      ]},
      { :r => 2,  :entries => [
        { :name => "idleLeft",  :start => 1, :end => 4 },
        { :name => "idleRight", :start => 5, :end => 8 },
      ]},
      { :r => 3,  :entries => [
        { :name => "walkDown",  :start => 1, :end => 6 },
        { :name => "walkUp_a",  :start => 7, :end => 8 },
      ]},
      { :r => 4,  :entries => [
        { :name => "walkUp_b",    :start => 1, :end => 4 },
        { :name => "walkLeft_a",  :start => 5, :end => 8 },
      ]},
      { :r => 5,  :entries => [
        { :name => "walkLeft_b", :start => 1, :end => 2 },
        { :name => "walkRight",  :start => 3, :end => 8 },
      ]},
      { :r => 6,  :entries => [
        { :name => "runDown", :start => 1, :end => 6 },
        { :name => "runUp_a", :start => 7, :end => 8 },
      ]},
      { :r => 7,  :entries => [
        { :name => "runUp_b",   :start => 1, :end => 4 },
        { :name => "runLeft_a", :start => 5, :end => 8 },
      ]},
      { :r => 8,  :entries => [
        { :name => "runLeft_b", :start => 1, :end => 2 },
        { :name => "runRight",  :start => 3, :end => 8 },
      ]},
      { :r => 9,  :entries => [
        { :name => "pickupDown", :start => 1, :end => 4 },
        { :name => "pickupUp",   :start => 5, :end => 8 },
      ]},
      { :r => 10, :entries => [
        { :name => "pickupLeft",  :start => 1, :end => 4 },
        { :name => "pickupRight", :start => 5, :end => 8 },
      ]},
      { :r => 11, :entries => [
        { :name => "pickaxeDown", :start => 1, :end => 4 },
        { :name => "pickaxeUp",   :start => 5, :end => 8 },
      ]},
      { :r => 12, :entries => [
        { :name => "pickaxeLeft",  :start => 1, :end => 4 },
        { :name => "pickaxeRight", :start => 5, :end => 8 },
      ]},
      { :r => 13, :entries => [
        { :name => "axe_chopDown", :start => 1, :end => 4 },
        { :name => "axe_chopUp",   :start => 5, :end => 8 },
      ]},
      { :r => 14, :entries => [
        { :name => "axe_chopLeft",  :start => 1, :end => 4 },
        { :name => "axe_chopRight", :start => 5, :end => 8 },
      ]},
      { :r => 15, :entries => [
        { :name => "plantDown",   :start => 1, :end => 3 },
        { :name => "plantUp",     :start => 4, :end => 6 },
        { :name => "plantLeft_a", :start => 7, :end => 8 },
      ]},
      { :r => 16, :entries => [
        { :name => "plantLeft_b", :start => 1, :end => 1 },
        { :name => "plantRight",  :start => 2, :end => 4 },
        { :name => "waterDown",   :start => 5, :end => 8 },
      ]},
      { :r => 17, :entries => [
        { :name => "waterUp",   :start => 1, :end => 4 },
        { :name => "waterLeft", :start => 5, :end => 8 },
      ]},
      { :r => 18, :entries => [
        { :name => "waterRight", :start => 1, :end => 4 },
        { :name => "reapDown",   :start => 5, :end => 8 },
      ]},
      { :r => 19, :entries => [
        { :name => "reapUp",   :start => 1, :end => 4 },
        { :name => "reapLeft", :start => 5, :end => 8 },
      ]},
      { :r => 20, :entries => [
        { :name => "reapRight", :start => 1, :end => 4 },
        { :name => "unused",    :start => 5, :end => 8 },
      ]},
      { :r => 21, :entries => [
        { :name => "hoeDown", :start => 1, :end => 4 },
        { :name => "hoeUp",   :start => 5, :end => 8 },
      ]},
      { :r => 22, :entries => [
        { :name => "hoeLeft",  :start => 1, :end => 4 },
        { :name => "hoeRight", :start => 5, :end => 8 },
      ]},
      { :r => 23, :entries => [
        { :name => "axe_strikeDown", :start => 1, :end => 4 },
        { :name => "axe_strikeUp",   :start => 5, :end => 8 },
      ]},
      { :r => 24, :entries => [
        { :name => "axe_strikeLeft",  :start => 1, :end => 4 },
        { :name => "axe_strikeRight", :start => 5, :end => 8 },
      ]},
    ]
  }

  ACTION_ALIASES = {
    "idle" => :idle,
    "walk" => :walk,
    "run"  => :run,
    "pickup" => :pickup, "pick up" => :pickup, "pick-up" => :pickup, "pick" => :pickup,
    "pickaxe" => :pickaxe, "pick axe" => :pickaxe, "mining" => :pickaxe,
    "axe_chop" => :axe_chop, "chop" => :axe_chop, "chopping" => :axe_chop,
    "plant" => :plant, "sow" => :plant, "seed" => :plant,
    "water" => :water, "watering" => :water,
    "reap" => :reap, "scythe" => :reap,
    "axe_strike" => :axe_strike,
    "hoe" => :hoe,
  }

  def self.scale
    SCALE_PCT / 100.0
  end

  def self.yoff_scaled
    Y_OFFSET * scale
  end

  def self.is_memao_name?(name)
    n = String(name || "")
    n.downcase.end_with?("_$(memao)")
  end

  def self.dir_name(d)
    case d
    when 2 then "Down"
    when 4 then "Left"
    when 6 then "Right"
    when 8 then "Up"
    else "Down"
    end
  end

  def self.range_table
    @range_table ||= begin
      map = ROW_MAP_OVERRIDE || DEFAULT_ROW_MAP
      out = {}
      (map[:rows] || []).each do |row|
        r = row[:r].to_i
        (row[:entries] || []).each do |e|
          frames = []
          (e[:start].to_i..e[:end].to_i).each { |i| frames << i }
          out[String(e[:name])] = { :row => r, :frames => frames }
        end
      end
      out
    end
  end

  def self.pick_idle_ranges(dir)
    d = dir_name(dir)
    r = range_table["idle#{d}"]
    r ? [r] : []
  end

  def self.pick_walk_ranges(dir)
    d = dir_name(dir)
    if d == "Up"
      a = range_table["walkUp_a"]; b = range_table["walkUp_b"]
      return (a && b) ? [a, b] : (range_table["walkUp"] ? [range_table["walkUp"]] : [])
    end
    if d == "Left"
      a = range_table["walkLeft_a"]; b = range_table["walkLeft_b"]
      return (a && b) ? [a, b] : (range_table["walkLeft"] ? [range_table["walkLeft"]] : [])
    end
    r = range_table["walk#{d}"]
    r ? [r] : []
  end

  def self.pick_run_ranges(dir)
    d = dir_name(dir)
    if d == "Up"
      a = range_table["runUp_a"]; b = range_table["runUp_b"]
      return (a && b) ? [a, b] : (range_table["runUp"] ? [range_table["runUp"]] : [])
    end
    if d == "Left"
      a = range_table["runLeft_a"]; b = range_table["runLeft_b"]
      return (a && b) ? [a, b] : (range_table["runLeft"] ? [range_table["runLeft"]] : [])
    end
    r = range_table["run#{d}"]
    r ? [r] : []
  end

  def self.pick_action_ranges(action_sym, dir)
    d = dir_name(dir)
    base = String(action_sym || "idle").downcase
    out = []

    if base == "plant" && d == "Left"
      a = range_table["plantLeft_a"]; b = range_table["plantLeft_b"]
      out << a if a
      out << b if b
    end

    if out.empty?
      single = range_table["#{base}#{d}"]
      out << single if single
    end

    out = pick_idle_ranges(dir) if out.empty?
    out
  end

  def self.build_seq(ranges, pingpong, is_idle)
    seq = []
    (ranges || []).each do |seg|
      (seg[:frames] || []).each do |col|
        seq << { :row => seg[:row], :col => col }
      end
    end

    if is_idle && !seq.empty?
      extended = []
      seq.each_with_index do |f, i|
        if i == 0
          4.times { extended << f }  # hold first idle frame
        else
          extended << f
        end
      end
      seq = extended
    end

    if pingpong && seq.length >= 2
      back = seq[0...-1].reverse
      seq = seq + back
    end

    seq
  end

  def self.normalize_action(action)
    return :idle if action.nil?
    return action if action.is_a?(Symbol)
    s = String(action).strip.downcase
    ACTION_ALIASES[s] || :idle
  end

  def self.resolve_target(which, interpreter, event_id=nil)
    case which
    when :player, "player"
      $game_player
    when :thisEvent, :this_event, "thisEvent", "this_event"
      return nil unless interpreter
      eid = interpreter.event_id
      eid && eid > 0 ? $game_map.events[eid] : nil
    when :eventId, :event_id, "eventId", "event_id"
      n = event_id.to_i
      n > 0 ? $game_map.events[n] : nil
    else
      nil
    end
  end

  def self.play_action(target=:player, action=:idle, direction=:current, loop=false, event_id=0, interpreter=nil)
    ch = resolve_target(target, interpreter, event_id)
    return unless ch

    dir = ch.direction
    case direction
    when :up, "up"       then dir = 8
    when :down, "down"   then dir = 2
    when :left, "left"   then dir = 4
    when :right, "right" then dir = 6
    else
      # :current
    end

    action_sym = normalize_action(action)

    st = ch.memao_state
    st[:mode]   = :manual
    st[:action] = action_sym
    st[:dir]    = dir
    st[:loop]   = !!loop
    st[:done]   = false
    st[:cycles] = (st[:cycles] || 0)

    ch.memao_locked = true

#    if wait && interpreter
#      interpreter.memao_wait_for(ch, 1)
#    end
  end

  def self.stop_action(target=:player, event_id=0, interpreter=nil)
    ch = resolve_target(target, interpreter, event_id)
    return unless ch
    st = ch.memao_state
    st[:mode] = :auto
    st[:done] = true
    ch.memao_locked = false
  end
end

#==============================================================================
# Game_CharacterBase: state + lock for autonomous movement (VX Ace uses update_move)
#==============================================================================

class Game_CharacterBase
  attr_accessor :memao_locked

  def memao_state
    @memao_state ||= { :mode => :auto, :loop => false, :done => false, :cycles => 0, :action => :idle, :dir => 2 }
  end

  alias cloud_memao_update_move update_move
  def update_move
    return if @memao_locked
    cloud_memao_update_move
  end
end

#==============================================================================
# Game_Player: lock for player input movement
# VX Ace uses movable? as the movement gate.
#==============================================================================

class Game_Player < Game_Character
  alias cloud_memao_movable movable?
  def movable?
    return false if @memao_locked
    cloud_memao_movable
  end

  # Some script stacks call/define can_move? (not stock-reliable). If it exists, hook it too.
  if method_defined?(:can_move?)
    alias cloud_memao_can_move can_move?
    def can_move?
      return false if @memao_locked
      cloud_memao_can_move
    end
  end
end

#==============================================================================
# Game_Interpreter: wait mode "memao"
#==============================================================================

class Game_Interpreter
  def wait_for_memao(character)
    return unless character
    while character.memao_state[:mode] == :manual
      @wait_count = 1
      Fiber.yield
    end
  end
end

#==============================================================================
# Sprite_Memao: keep Sprite_Character for balloons/priority/opacity behavior
#==============================================================================

class Sprite_Memao < Sprite_Character
  def initialize(viewport, character)
    super(viewport, character)
    self.ox = CloudMemao::CELL_W / 2
    self.oy = CloudMemao::CELL_H
    @memao_timer = 0
    @memao_fps = CloudMemao::IDLE_FPS
    @memao_frame_index = 0
    @memao_seq = []
    @memao_key = ""
    @memao_move_hold = 0

    self.zoom_x = CloudMemao.scale
    self.zoom_y = CloudMemao.scale
  end

  def memao_dashing?(ch)
    return ch.dash? if ch.is_a?(Game_Player)
    return $game_player && $game_player.dash?
  end

  def update_position
    ch = @character
    x = ch.screen_x + CloudMemao::X_OFFSET
    y = ch.screen_y + CloudMemao.yoff_scaled
    if CloudMemao::CRISP_PIXELS
      self.x = x.round
      self.y = y.round
    else
      self.x = x
      self.y = y
    end
    self.z = ch.screen_z
  end

  def update_src_rect
    memao_update_anim
  end

  def memao_update_anim
    return unless self.bitmap
    ch = @character
    st = ch.memao_state

    moving_now = ch.moving?
    @memao_move_hold ||= 0
    if moving_now
      @memao_move_hold = CloudMemao::WALK_HOLD_FRAMES
    elsif @memao_move_hold > 0
      @memao_move_hold -= 1
    end
    moving_smooth = moving_now || @memao_move_hold > 0

    dir = ch.direction
    dashing = memao_dashing?(ch)

    ranges = []
    fps = CloudMemao::IDLE_FPS
    key = ""

    if st[:mode] == :manual
      manual_dir = st[:dir] || dir
      ranges = CloudMemao.pick_action_ranges(st[:action], manual_dir)
      fps = CloudMemao::ACTION_FPS
      key = "act:#{st[:action]}:#{manual_dir}"
    elsif !moving_smooth
      ranges = CloudMemao.pick_idle_ranges(dir)
      fps = CloudMemao::IDLE_FPS
      key = "idle:#{dir}"
    elsif dashing
      ranges = CloudMemao.pick_run_ranges(dir)
      fps = CloudMemao::RUN_FPS
      key = "run:#{dir}"
    else
      ranges = CloudMemao.pick_walk_ranges(dir)
      fps = CloudMemao::WALK_FPS
      key = "walk:#{dir}"
    end

    if ranges.nil? || ranges.empty?
      ranges = CloudMemao.pick_idle_ranges(2)
      fps = CloudMemao::IDLE_FPS
      key = "idle:2"
    end

    if @memao_key != key || @memao_fps != fps
      @memao_key = key
      @memao_fps = fps

      pingpong = (st[:mode] == :manual && st[:action] == :water)
      is_idle = (st[:mode] != :manual && key.start_with?("idle:")) || (st[:mode] == :manual && st[:action] == :idle)

      @memao_seq = CloudMemao.build_seq(ranges, pingpong, is_idle)
      @memao_frame_index = 0
      @memao_timer = 0
      memao_draw_current
    end

    frames_per_tick = 60.0 / [1, @memao_fps].max
    @memao_timer += 1
    if @memao_timer >= frames_per_tick && @memao_seq && !@memao_seq.empty?
      @memao_timer = 0
      @memao_frame_index = (@memao_frame_index + 1) % @memao_seq.length

      if st[:mode] == :manual && !st[:loop] && @memao_frame_index == 0
        st[:done] = true
        st[:mode] = :auto
        ch.memao_locked = false
        st[:cycles] = (st[:cycles] || 0) + 1
      elsif st[:mode] == :manual && @memao_frame_index == 0
        st[:cycles] = (st[:cycles] || 0) + 1
      end

      memao_draw_current
    end
  end

  def memao_draw_current
    return if @memao_seq.nil? || @memao_seq.empty?
    f = @memao_seq[@memao_frame_index % @memao_seq.length]
    sx = (f[:col] - 1) * CloudMemao::CELL_W
    sy = (f[:row] - 1) * CloudMemao::CELL_H
    self.src_rect.set(sx, sy, CloudMemao::CELL_W, CloudMemao::CELL_H)
  end
end

#==============================================================================
# Spriteset_Map: replace sprites for memao characters (VX Ace safe)
#==============================================================================

class Spriteset_Map
  alias cloud_memao_create_characters create_characters
  def create_characters
    cloud_memao_create_characters
    refresh_memao_character_sprites
  end

  def refresh_memao_character_sprites
    return unless @character_sprites
    @character_sprites.each_with_index do |spr, i|
      ch = spr && spr.character
      next unless ch
      want = CloudMemao.is_memao_name?(ch.character_name)
      has  = spr.is_a?(Sprite_Memao)
      if want && !has
        replace_character_sprite(i, Sprite_Memao.new(@viewport1, ch))
      elsif !want && has
        replace_character_sprite(i, Sprite_Character.new(@viewport1, ch))
      end
    end
  end

  def replace_character_sprite(index, new_sprite)
    old = @character_sprites[index]
    old.dispose if old && !old.disposed?
    @character_sprites[index] = new_sprite
  end
end

#==============================================================================
# Scene_Map: periodic refresh (handles page changes / graphic swaps)
#==============================================================================

class Scene_Map < Scene_Base
  alias cloud_memao_update update
  def update
    cloud_memao_update
    return unless @spriteset
    @memao_refresh_t ||= 0
    @memao_refresh_t += 1
    if @memao_refresh_t >= 20
      @memao_refresh_t = 0
      if @spriteset.respond_to?(:refresh_memao_character_sprites)
        @spriteset.refresh_memao_character_sprites
      end
    end
  end
end
