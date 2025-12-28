# frozen_string_literal: true

class Lamer
  module FFI
    # VBR mode enumeration from lame.h
    VBR_MODE = enum :vbr_mode, [
      :vbr_off, 0,
      :vbr_mt,
      :vbr_rh,
      :vbr_abr,
      :vbr_mtrh,
      :vbr_max_indicator
    ]

    # MPEG mode enumeration from lame.h
    MPEG_MODE = enum :mpeg_mode, [
      :stereo, 0,
      :joint_stereo,
      :dual_channel,
      :mono,
      :not_set,
      :max_indicator
    ]

    # Preset modes
    PRESET_MODE = enum :preset_mode, [
      :v9, 410,
      :v8, 420,
      :v7, 430,
      :v6, 440,
      :v5, 450,
      :v4, 460,
      :v3, 470,
      :v2, 480,
      :v1, 490,
      :v0, 500,
      :r3mix, 1000,
      :standard, 1001,
      :extreme, 1002,
      :insane, 1003,
      :standard_fast, 1004,
      :extreme_fast, 1005,
      :medium, 1006,
      :medium_fast, 1007
    ]
  end
end
