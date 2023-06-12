#==============================================================================
# 
# ▼ CloudTheWolf - Casting Animation for Yami Engine Symphony - 8D/Kaduki Battlers
# -- Created By CloudTheWolf
# -- Last Updated: 2023.06.12
# -- Requires: Yami Engine Symphony
#              Yami Engine Symphony - Add-on: 8D/Kaduki Battlers     
#
#
# -- Licence: Free for commercial and non-commercial use.
#             Please Credit CloudTheWolf as well as Yami and Yanfly 
#             (You should already be crediting both anyway if you use this :P )
#
#==============================================================================
#==============================================================================
# ▼ Credits
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Symphony Tags: Yanfly (From his Melody Tags).
# Yami Engine Sympony: Yami
# 
#==============================================================================
#==============================================================================
# ▼ USE
#==============================================================================
# In the database, add one the following tags to your skills Note block
# 
# <cast pose: channeling>
# <cast pose: victory>
# <cast pose: ready>
# <cast pose: critical>
# <cast pose: cast>
# <cast pose: fallen>
# <cast pose: dead>
# <cast pose: critical>
# <cast pose: marching>
#
#==============================================================================
# ▼ Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script is made strictly for RPG Maker VX Ace. It is highly unlikely that
# it will run with RPG Maker VX without adjusting.
# Remember to put this script under Battle Symphony
#
# As per Yami Engine Symphony, the pose is based on the following Character
# Sheet Layout
#==============================================================================
#    Down            Down Left       Down Dash       Down Left Dash
#    Left            Upper Left      Left Dash       Upper Left Dash
#    Right           Down Right      Right Dash      Down Right Dash
#    Up              Upper Right     Up Dash         Up Right Dash
# 
#    Ready/Idle      Victory Pose    2H Swing        
#    Damage          Evade/Dodge     1H Swing        
#    Dazed/Critical  Dead 1-3        Cast/Use Item   
#    Marching        Downed/Fallen   Channeling      
#==============================================================================
$imported = {} if $imported.nil?
$imported["CTW-CastAnimation"] = true

class Scene_Battle < Scene_Base
  
  @@pose_types = [
    :channeling,
    :victory,
    :ready,
    :critical,
    :cast,
    :fallen,
    :dead,
    :critical, 
    :marching
  ]
    
  alias ctw_casting_animation_skill_ok on_skill_ok
  def on_skill_ok            
    ctw_casting_animation_skill_ok
    skill = @skill_window.item
    battler = BattleManager.actor
    if skill && skill.note =~ /<cast pose: (\S+)>/
      @pose = $1.to_sym
      @@pose_types.each do |item|
        battler.force_pose_8d(@pose) ; return if item == @pose
      end        
    end    
  end

  alias ctw_casting_animation_on_enemy_cancel on_enemy_cancel
  def on_enemy_cancel
      ctw_casting_animation_on_enemy_cancel      
      battler = BattleManager.actor
      battler.force_pose_8d(:ready)
  end
    
  alias ctw_casting_animation_on_actor_cancel on_actor_cancel
  def on_actor_cancel      
    battler = BattleManager.actor  
    battler.force_pose_8d(:ready)    
    ctw_casting_animation_on_actor_cancel
  end    
end
