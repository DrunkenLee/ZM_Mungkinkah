require "ATA2TuningTable"

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local carRecipe = "ATAJeepRecipes"

local NewCarTuningTable = {}
NewCarTuningTable["ATAJeep"] = {
    addPartsFromVehicleScript = "",
    parts = {}
}

NewCarTuningTable["ATAJeep"].parts["ATA2Bumper"] = {
    Bumper2 = {
        spawnChance = 50, -- значение от 0 до 100. По умолчанию - 0.
        icon = "media/ui/tuning2/jeep_bumper_2.png",
        name = "IGUI_ATA2_Bumper_Winch", -- необязательно
        category = "Bumpers", 
        install = { -- предметы и правила крафта/установки детали
            weight = "auto",
            animation = "ATA_PickLock",
            transmitFirstItemCondition = true,
            use = {
                Autotsar__ATAJeepBumper2Item = 1,
                Screws=6,
            },
            tools = {
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 3,
            },
            recipes = {"Basic Mechanics"},
            time = 20, 
        },
        uninstall = { -- предметы и правила демонтажа детали
            weight = "auto",
            animation = "ATA_PickLock",
            tools = {
                primary = "Base.Wrench",
            },
            skills = { -- необязательно
                Mechanics = 2,
            },
            recipes = {"Basic Mechanics"},
            transmitConditionOnFirstItem = true,
            result = {
                Autotsar__ATAJeepBumper2Item = 1,
                Screws=3,
            },
            time = 20,
        }
    },
    Bumper3 = {
        spawnChance = 10,
        icon = "media/ui/tuning2/jeep_bumper_3.png",
        name = "IGUI_ATA2_Bullbar",
        category = "Bumpers",
        protection = {"HeadlightLeft", "HeadlightRight"},
        install = {
            weight = "auto",
            animation = "ATA_PickLock",
            transmitFirstItemCondition = true,
            use = {
                Autotsar__ATAJeepBumper3Item = 1,
                Screws=8,
            },
            tools = {
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 4,
            },
            recipes = {"Basic Mechanics"},
            time = 20, 
        },
        uninstall = {
            animation = "ATA_PickLock",
            tools = {
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 2,
            },
            recipes = {"Basic Mechanics"},
            transmitConditionOnFirstItem = true,
            result = {
                Autotsar__ATAJeepBumper3Item = 1,
                Screws=4,
            },
            time = 20,
        }
    },
    Bumper1 = {
        spawnChance = 100, -- значение от 0 до 100. По умолчанию - 0.
        icon = "media/ui/tuning2/jeep_bumper_1.png",
        name = "IGUI_ATA2_Bumper_Classic",
        category = "Bumpers",
        install = { -- предметы и правила крафта/установки детали
            weight = "auto",
            animation = "ATA_PickLock",
            transmitFirstItemCondition = true,
            use = { -- необязательно
                Autotsar__ATAJeepBumper1Item = 1,
                Screws=4,
            },
            tools = {
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 3,
            },
            recipes = {"Basic Mechanics"},
            time = 15, 
        },
        uninstall = { -- предметы и правила демонтажа детали
            animation = "ATA_PickLock",
            tools = {
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 2,
            },
            transmitConditionOnFirstItem = true,
            result = {
                Autotsar__ATAJeepBumper1Item = 1,
                Screws=2,
            },
            time = 15,
        }
    },
    Bumper4 = {
        icon = "media/ui/tuning2/jeep_bumper_4.png",
        name = "IGUI_ATA2_Bumper_Lethal", -- необязательно
        category = "Bumpers",
        protection = {"EngineDoor", "HeadlightLeft", "HeadlightRight"}, 
        removeIfBroken = true,
        install = { -- предметы и правила крафта/установки детали
            weight = "auto",
            animation = "ATA_PickLock",
            use = { -- необязательно
                MetalPipe = 4,
                SmallSheetMetal = 5,
                SheetMetal = 2,
                MetalBar=2,
                Screws=4,
                BlowTorch = 10,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask", -- предмет, который будет одеваться на тело. Модуль обязателен.
                primary = "Base.Wrench", -- Модуль обязателен.
            },
            skills = { -- необязательно
                Mechanics = 4,
                MetalWelding = 8,
            },
            recipes = {"Basic Mechanics", carRecipe}, -- необязательно
            time = 65, 
        },
        uninstall = { -- предметы и правила демонтажа детали
            animation = "ATA_IdleLeverOpenLow",
            use = { -- необязательно
                BlowTorch=6,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            skills = { -- необязательно
                MetalWelding = 2,
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindowFrontLeft"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_side.png",
        category = "Protection",
        protection = {"WindowFrontLeft"},
        removeIfBroken = true,
        disableOpenWindowFromSeat = "SeatFrontLeft",
        install = {
            weight = "auto",
            use = {
                MetalBar = 4,
                BlowTorch = 4,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
            },
            skills = {
                MetalWelding = 3,
            },
            recipes = {carRecipe},
            requireInstalled = {"WindowFrontLeft"},
            time = 65, 
        },
        uninstall = {
            animation = "ATA_IdleLeverOpenMid",
            tools = {
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindowFrontRight"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_side.png",
        category = "Protection",
        protection = {"WindowFrontRight"},
        disableOpenWindowFromSeat = "SeatFrontRight",
        removeIfBroken = true,
        install = {
            weight = "auto",
            use = {
                MetalBar = 4,
                BlowTorch = 4,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
            },
            skills = {
                MetalWelding = 3,
            },
            recipes = {carRecipe},
            requireInstalled = {"WindowFrontRight"},
            time = 65, 
        },
        uninstall = {
            animation = "ATA_IdleLeverOpenMid",
            tools = {
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindowRearLeft"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_side.png",
        category = "Protection",
        protection = {"WindowRearLeft"},
        disableOpenWindowFromSeat = "SeatRearLeft",
        removeIfBroken = true,
        install = {
            weight = "auto",
            use = {
                MetalBar = 4,
                BlowTorch = 4,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
            },
            skills = {
                MetalWelding = 3,
            },
            recipes = {carRecipe},
            requireInstalled = {"WindowRearLeft"},
            time = 65, 
        },
        uninstall = {
            animation = "ATA_IdleLeverOpenMid",
            tools = {
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindowRearRight"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_side.png",
        category = "Protection",
        protection = {"WindowRearRight"},
        disableOpenWindowFromSeat = "SeatRearRight",
        removeIfBroken = true,
        install = {
            weight = "auto",
            use = {
                MetalBar = 4,
                BlowTorch = 4,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
            },
            skills = {
                MetalWelding = 3,
            },
            recipes = {carRecipe},
            requireInstalled = {"WindowRearRight"},
            time = 65, 
        },
        uninstall = {
            animation = "ATA_IdleLeverOpenMid",
            tools = {
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindshield"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_windshield.png",
        category = "Protection",
        protection = {"Windshield"},
        removeIfBroken = true,
        install = {
            weight = "auto",
            area = "TireFrontLeft",
            use = {
                MetalPipe = 2,
                SheetMetal = 3,
                SmallSheetMetal = 4,
                MetalBar = 4,
                Screws = 8,
                BlowTorch = 8,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
                primary = "Base.Wrench",
            },
            skills = {
                MetalWelding = 4,
            },
            recipes = {carRecipe},
            requireInstalled = {"Windshield"},
            time = 65, 
        },
        uninstall = {
            area = "TireFrontLeft",
            animation = "ATA_Crowbar_DoorLeft",
            tools = {
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWindshieldRear"] = {
    Default = {
        icon = "media/ui/tuning2/protection_window_windshield.png",
        category = "Protection",
        protection = {"WindshieldRear"},
        removeIfBroken = true,
        install = {
            weight = "auto",
            area = "TireRearRight",
            use = {
                MetalBar = 15,
                BlowTorch = 10,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
            },
            skills = {
                MetalWelding = 4,
            },
            recipes = {carRecipe},
            requireInstalled = {"WindshieldRear"},
            time = 65, 
        },
        uninstall = {
            area = "TireRearRight",
            animation = "ATA_IdleLeverOpenMid",
            tools = {
                both = "Base.Crowbar",
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2RoofBase"] = {
    Default = {
        icon = "media/ui/tuning2/roof_base.png",
        category = "Trunks",
        install = {
            area = "ATARoof",
            weight = "auto",
            use = {
                MetalPipe = 6,
                BlowTorch=5,
                Screws=4,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask", -- предмет, который будет одеваться на тело. Модуль обязателен.
                primary = "Base.Wrench", -- Модуль обязателен.
            },
            skills = {
                MetalWelding = 4,
            },
            time = 65, 
        },
        uninstall = {
            area = "ATARoof",
            animation = "ATA_IdleLeverOpenHigh",
            use = {
                BlowTorch=5,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            skills = {
                MetalWelding = 2,
            },
            result = "auto",
            requireUninstalled = {"ATA2InteractiveTrunkRoofRack", "ATA2RoofTent"},
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2RoofTent"] = {
    Default = {
        icon = "media/ui/tuning2/roof_tent.png",
        category = "Another",
        install = {
            weight = "auto",
            area = "ATARoof",
            use = {
                Autotsar__ATAJeepRoofTentItem = 1,
                Screws=4,
            },
            tools = { -- необязательно
                primary = "Base.Wrench", -- Модуль обязателен.
            },
            requireInstalled = {"ATA2RoofBase"},
            requireUninstalled = {"ATA2InteractiveTrunkRoofRack"},
            time = 65, 
        },
        uninstall = {
            area = "ATARoof",
            animation = "ATA_IdleLeverOpenHigh",
            use = {
                BlowTorch=5,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            result = {
                Autotsar__ATAJeepRoofTentItem = 1,
                Screws=3,
            },
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2InteractiveTrunkRoofRack"] = {
    ATA_Jeep_roofrack = {
        icon = "media/ui/tuning2/roof_rack_2.png",
        category = "Trunks",
        containerCapacity = 60,
        interactiveTrunk = {
            filling = {"ATA_Jeep_roofrack_bag1", "ATA_Jeep_roofrack_bag2", "ATA_Jeep_roofrack_bag3"},
            items = {
                {
                    itemTypes = {"BoxOfJars"},
                    modelNameByCount = {"ATA_Jeep_roofrack_BoxOfJars1", "ATA_Jeep_roofrack_BoxOfJars2", },
                },
                {
                    itemTypes = {"BucketEmpty", "BucketConcreteFull", "BucketPlasterFull", "BucketWaterFull", },
                    modelNameByCount = {"ATA_Jeep_roofrack_Bucket"},
                },
                {
                    itemTypes = {"FishingNet", "BrokenFishingNet", },
                    modelNameByCount = {"ATA_Jeep_roofrack_FishingNet"},
                },
                {
                    itemTypes = {"Generator"},
                    modelNameByCount = {"ATA_Jeep_roofrack_Generator"},
                },
                {
                    itemTypes = {"Saw",},
                    modelNameByCount = {"ATA_Jeep_roofrack_Hacksaw"},
                },
                {
                    itemTypes = {"Log", "LogStacks2", "LogStacks3", "LogStacks4", "Plank", },
                    modelNameByCount = {"ATA_Jeep_roofrack_Log"},
                },
                {
                    itemTypes = {"LugWrench"},
                    modelNameByCount = {"ATA_Jeep_roofrack_LugWrench"},
                },
                {
                    itemTypes = {"PropaneTank"},
                    modelNameByCount = {"ATA_Jeep_roofrack_PropaneTank1", "ATA_Jeep_roofrack_PropaneTank2", },
                },
                {
                    itemTypes = {"TrapCage"},
                    modelNameByCount = {"ATA_Jeep_roofrack_w001"},
                },
            }
        },
        install = { -- предметы и правила крафта/установки детали
            weight = "auto",
            use = {
                MetalPipe = 12,
                MetalBar = 4,
                BlowTorch=10,
                Screws=4,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask", -- предмет, который будет одеваться на тело. Модуль обязателен.
                primary = "Base.Wrench", -- Модуль обязателен.
            },
            skills = {
                MetalWelding = 5,
            },
            recipes = {carRecipe}, -- необязательно. Варианты: "Basic Mechanics"
            requireInstalled = {"ATA2RoofBase"},  -- необязательно
            requireUninstalled = {"ATA2RoofTent"},
            time = 65, 
        },
        uninstall = {
            animation = "ATA_IdleLeverOpenHigh",
            use = {
                BlowTorch=5,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            skills = {
                MetalWelding = 2,
            },
            result = "auto",
            time = 65,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2InteractiveTrunkWheelRack"] = {
    WheelRack = {
        icon = "media/ui/tuning2/wheel_rack_1.png",
        category = "Trunks",
        containerCapacity = 25,
        interactiveTrunk = {
            filling = {"Cooler"},
            items = {
                {
                    itemTypes = {"Bag_BigHikingBag", "Bag_NormalHikingBag"},
                    modelNameByCount = {"BigHikingBag"},
                },
                {
                    itemTypes = {"Jack"},
                    modelNameByCount = {"Jack"},
                },
                {
                    itemTypes = {"Extinguisher"},
                    modelNameByCount = {"Extinguisher"},
                },
                {
                    itemTypes = {"PetrolCan", "EmptyPetrolCan"},
                    modelNameByCount = {"GasCan"},
                },
                {
                    itemTypes = {"Radio.RadioBlack", "Radio.RadioRed"},
                    modelNameByCount = {"Radio"},
                },
                {
                    itemTypes = {"Bag_JanitorToolbox"},
                    modelNameByCount = {"ToolBox"},
                },
                {
                    itemTypes = {"TirePump"},
                    modelNameByCount = {"TirePump"},
                },
            }
        },
        install = { -- предметы и правила крафта/установки детали
            weight = "auto",
            use = {
                MetalPipe = 4,
                MetalBar = 4,
                BlowTorch=5,
                Screws=4,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask", -- предмет, который будет одеваться на тело. Модуль обязателен.
                primary = "Base.Wrench", -- Модуль обязателен.
            },
            skills = {
                MetalWelding = 3,
            },
            recipes = {carRecipe}, -- необязательно. Варианты: "Basic Mechanics"
            requireInstalled = {"ATASpareWheel"},  -- необязательно
            time = 40, 
        },
        uninstall = { -- предметы и правила демонтажа детали
            animation = "ATA_IdleLeverOpenMid",
            use = { -- необязательно. "__" заменяется на "."
                BlowTorch=3,
            },
            tools = { -- необязательно
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            skills = {
                MetalWelding = 2,
            },
            result = "auto", -- "__" заменяется на "."
            time = 40,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2ProtectionWheels"] = { -- не забыть сделать особые настройки колес
    ATAProtection = {
        removeIfBroken = true,
        icon = "media/ui/tuning2/wheel_chain.png",
        category = "Protection", 
        protectionModel = true, 
        protection = {"TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight"}, 
        install = { 
            sound = "ATA2InstallWheelChain",
            use = { 
                ATAProtectionWheelsChain = 1,
                BlowTorch = 4,
            },
            tools = { 
                bodylocation = "Base.WeldingMask", 
                primary = "Base.Wrench",
            },
            skills = {
                Mechanics = 2,
                MetalWelding = 3,
            },
            recipes = {"Basic Tuning"},
            requireInstalled = {"TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight"},
            time = 65, 
        },
        uninstall = {
            sound = "ATA2InstallWheelChain",
            use = {
                BlowTorch=4,
            },
            tools = {
                bodylocation = "Base.WeldingMask",
                both = "Base.Crowbar",
            },
            skills = {
                MetalWelding = 2,
            },
            result = {
                UnusableMetal=2,
            },
            time = 40,
        }
    }
}

NewCarTuningTable["ATAJeep"].parts["ATA2VisualSnorkel"] = {
    Default = {
        spawnChance = 20,
        icon = "media/ui/tuning2/snorkel.png",
        category = "Another",
        install = {
            transmitFirstItemCondition = true,
            use = {
                Autotsar__ATAJeepSnorkelItem = 1,
                Screws=4,
            },
            tools = {
                primary = "Base.Screwdriver",
            },
            skills = {
                Mechanics = 3,
            },
            requireInstalled = {"TrunkDoor"},
            recipes = {"Advanced Mechanics"},
            time = 30,
        },
        uninstall = {
            transmitConditionOnFirstItem = true,
            tools = {
                primary = "Base.Screwdriver",
            },
            recipes = {"Advanced Mechanics"},
            result = {
                Autotsar__ATAJeepSnorkelItem=1,
                Screws=3,
            },
            time = 30,
        }
    }
}

NewCarTuningTable["ATAJeepArcher"] = NewCarTuningTable["ATAJeep"]
NewCarTuningTable["ATAJeepRubicon"] = NewCarTuningTable["ATAJeep"]
NewCarTuningTable["ATAJeepClassic"] = NewCarTuningTable["ATAJeep"]

ATA2Tuning_AddNewCars(NewCarTuningTable)
