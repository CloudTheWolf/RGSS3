#===============================================================================
#
# CloudTheWolf Event Sounds
# Author: CloudTheWolf
# Date (18/06/2023)
# Version: (1.0.0) (VXA)
# Level: (Easy)
#
# Website: https://cloudthewolf.com/
#
#===============================================================================
#
# NOTES: 1)This script will only work with ace.
#        2) This will only work with the closest event.
#
#===============================================================================
#
# Description: Adds a BGS Sound Source to an event
#
# Credits: Me (CloudTheWolf)
#
#===============================================================================
#
# Instructions
# Paste above ▼ Below and above ▼ Main Process.
# 
# Add the following comment to your event:
# [sound "SOUND_NAME" max_volume min_volume range]
# 
#  Eg.
#  [sound "Fire" 50 2 7] 
#
#  This will play to firew BGS when the player is within the range.
#  Outside of the range it will play at the min_volume so set to 0 if you don't
#  want it on the while map
#
#  FAQ:
#
#  Q: Can I have more than 1 sound source on a map?
#  A: Yes, however, please not only 1 can play at a time.
#     This is based on which ever is closest to the player.
#  Q: The BGS Still plays even when leaving the map
#  A: In your Map Settings just enable "Change BGS" and set it to none. 
# 
#  Q: Does this work with X, Y or Z?
#  A: This has not been testing with other scripts so this may or may not work
#     
#===============================================================================
#
# Free for any use as long as I'm credited.
#
#===============================================================================


#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
#  This class handles maps. It includes scrolling and passage determination
# functions. The instance of this class is referenced by $game_map.
#==============================================================================

class Game_Map
  
  # Calculate the straight-line distance between two points
  def distance(x1, y1, x2, y2)
    Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
  end

# Update BGS settings for events on the map
  def update_event_sounds
    closest_event = nil
    closest_distance = Float::INFINITY
    closest_range = nil

    events.each_value do |event|
      comment = event.list.select { |command| command.code == 108 || command.code == 408 }
      next unless comment

      sound_matches = comment.map { |command| command.parameters[0].match(/\[sound\s+"(.+)"\s+(\d+)\s+(\d+)\s+(\d+)\]/) }.compact

      sound_matches.each do |sound_match|
        bgs_name = sound_match[1]
        max_volume = sound_match[2].to_i
        min_volume = sound_match[3].to_i
        range = sound_match[4].to_i

        player = $game_player
        distance = distance(event.x, event.y, player.x, player.y)            
        
        if closest_event == nil || (distance <= range && distance < closest_distance)
          closest_event = event
          closest_distance = distance
          closest_range = range
        end
      end
    end

    if closest_event      
      comment = closest_event.list.select { |command| command.code == 108 || command.code == 408 }
      sound_match = comment.map { |command| command.parameters[0].match(/\[sound\s+"(.+)"\s+(\d+)\s+(\d+)\s+(\d+)\]/) }.compact.first
      bgs_name = sound_match[1]
      max_volume = sound_match[2].to_i
      min_volume = sound_match[3].to_i      
      if closest_distance <= closest_range
        current_volume = $temp_bgs_volume || 0
        target_volume = max_volume - ((max_volume - min_volume) * closest_distance / closest_range).to_i

        if current_volume != target_volume || $temp_bgs_name != bgs_name
          Audio.bgs_stop if current_volume == 0 && $temp_bgs_name != bgs_name
          Audio.bgs_play("Audio/BGS/#{bgs_name}", target_volume, 100, 0)
          $temp_bgs_name = bgs_name
        end

        $temp_bgs_volume = target_volume
      else
        Audio.bgs_play("Audio/BGS/#{bgs_name}", min_volume, 100, 0) unless min_volume == 0
      end
    end
  end
end

#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
#  This class performs the map screen processing.
#==============================================================================

class Scene_Map < Scene_Base
  
  # Update scene (called every frame)
  alias ces_update update
  def update
    ces_update
    update_dynamic_sounds
  end
  
  # Update dynamic sound effects
  def update_dynamic_sounds
    $game_map.update_event_sounds
  end  
end
