CREATE TABLE IF NOT EXISTS `player_drtokens` (
  `citizenid` varchar(50) NOT NULL,
  `tokens` int(11) NOT NULL DEFAULT 0,
  `last_reward` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insertar tokens por defecto para jugadores existentes (opcional)
-- INSERT IGNORE INTO `player_drtokens` (citizenid, tokens) 
-- SELECT citizenid, 0 FROM players;