--  Indexes required for bolagisering, total time to apply all indexes: ~40 minutes

ALTER TABLE webcert.HANDELSE
    ADD INDEX idx_handelse_enhets_timestamp (ENHETS_ID, TIMESTAMP),
  ALGORITHM=INPLACE,
  LOCK=NONE;

ALTER TABLE statistik.intygcommon
    ADD INDEX idx_ic_enhet_sign (enhet, signeringsdatum),
  ALGORITHM=INPLACE,
  LOCK=NONE;

ALTER TABLE statistik.messagewideline
    ADD INDEX idx_mwl_enhet_signeringsdatum (enhet, intygSigneringsdatum),
  ALGORITHM=INPLACE,
  LOCK=NONE;

ALTER TABLE statistik.wideline
    ADD INDEX idx_wl_enhet_correlationId (enhet, correlationId),
  ALGORITHM=INPLACE,
  LOCK=NONE;