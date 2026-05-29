-- Generado por Oracle SQL Developer Data Modeler 24.3.1.351.0831
--   en:        2026-05-28 21:48:00 CLT
--   sitio:      Oracle Database 21c
--   tipo:      Oracle Database 21c



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE actividad 
    ( 
     id_actividad                   NUMBER  NOT NULL , 
     estudiante_id_estudiante       NUMBER  NOT NULL , 
     usuario_id_usuario             NUMBER  NOT NULL , 
     pictograma_id_pictograma       NUMBER , 
     catalogo_actividad_id_catalogo NUMBER , 
     nombre_tarea                   VARCHAR2 (100)  NOT NULL , 
     hora_inicio                    VARCHAR2 (5)  NOT NULL , 
     hora_fin                       VARCHAR2 (5)  NOT NULL , 
     es_completada                  NUMBER (1) DEFAULT 0  NOT NULL , 
     fecha_actividad                DATE  NOT NULL , 
     fecha_creacion                 TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP  NOT NULL 
    ) 
;

ALTER TABLE actividad 
    ADD 
    CHECK (es_completada IN (0, 1)) 
;

COMMENT ON TABLE actividad IS 'Actividades/rutinas diarias asignadas a estudiantes'
;
CREATE INDEX idx_actividad_estudiante ON actividad 
    ( 
     estudiante_id_estudiante ASC 
    ) 
;
CREATE INDEX idx_actividad_creador ON actividad 
    ( 
     usuario_id_usuario ASC 
    ) 
;
CREATE INDEX idx_actividad_fecha ON actividad 
    ( 
     fecha_actividad ASC 
    ) 
;

ALTER TABLE actividad 
    ADD CONSTRAINT actividad_PK PRIMARY KEY ( id_actividad ) ;

CREATE TABLE catalogo_actividad 
    ( 
     id_catalogo              NUMBER  NOT NULL , 
     nombre_predeterminado    VARCHAR2 (100)  NOT NULL , 
     pictograma_id_pictograma NUMBER 
    ) 
;

COMMENT ON TABLE catalogo_actividad IS 'Actividades predefinidas reutilizables'
;

ALTER TABLE catalogo_actividad 
    ADD CONSTRAINT catalogo_actividad_PK PRIMARY KEY ( id_catalogo ) ;

CREATE TABLE configuracion_alerta 
    ( 
     id_alerta              NUMBER  NOT NULL , 
     actividad_id_actividad NUMBER  NOT NULL , 
     minutos_anticipacion   VARCHAR2 (2) DEFAULT '5'  NOT NULL , 
     tipo_sonido            VARCHAR2 (10) DEFAULT 'suave'  NOT NULL , 
     parpadeo_visual        NUMBER (1) DEFAULT 1  NOT NULL 
    ) 
;

ALTER TABLE configuracion_alerta 
    ADD 
    CHECK (minutos_anticipacion IN ('2', '5', '10', '15')) 
;

ALTER TABLE configuracion_alerta 
    ADD 
    CHECK (tipo_sonido IN ('moderado', 'silencio', 'suave')) 
;

ALTER TABLE configuracion_alerta 
    ADD 
    CHECK (parpadeo_visual IN (0, 1)) 
;

COMMENT ON TABLE configuracion_alerta IS 'Configuración de alertas 1:1 por actividad'
;

ALTER TABLE configuracion_alerta 
    ADD CONSTRAINT configuracion_alerta_PK PRIMARY KEY ( id_alerta ) ;

ALTER TABLE configuracion_alerta 
    ADD CONSTRAINT INDEX_1 UNIQUE ( actividad_id_actividad ) ;

CREATE TABLE curso 
    ( 
     id_curso        NUMBER  NOT NULL , 
     nivel_academico VARCHAR2 (10)  NOT NULL , 
     letra_academica VARCHAR2 (1) 
    ) 
;

COMMENT ON TABLE curso IS 'Cursos académicos (1 Básico a 8 Básico, letras A-B)'
;

ALTER TABLE curso 
    ADD CONSTRAINT curso_PK PRIMARY KEY ( id_curso ) ;

CREATE TABLE estudiante 
    ( 
     id_estudiante      NUMBER  NOT NULL , 
     nombre             VARCHAR2 (100)  NOT NULL , 
     fecha_nacimiento   DATE  NOT NULL , 
     codigo_vinculacion VARCHAR2 (7) , 
     puntos_totales     NUMBER DEFAULT 0  NOT NULL , 
     creado_en          TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP  NOT NULL , 
     usuario_id_usuario NUMBER  NOT NULL , 
     curso_id_curso     NUMBER  NOT NULL 
    ) 
;

COMMENT ON TABLE estudiante IS 'Datos extendidos del estudiante (niño con TEA/NEE). Relación 1:1 con usuario'
;
CREATE INDEX idx_estudiante_codigo ON estudiante 
    ( 
     codigo_vinculacion ASC 
    ) 
;
CREATE INDEX idx_estudiante_usuario ON estudiante 
    ( 
     usuario_id_usuario ASC 
    ) 
;

ALTER TABLE estudiante 
    ADD CONSTRAINT estudiante_PK PRIMARY KEY ( id_estudiante ) ;

ALTER TABLE estudiante 
    ADD CONSTRAINT INDEX_1v1 UNIQUE ( codigo_vinculacion ) ;

CREATE TABLE historial_cumplimiento 
    ( 
     id_log                 NUMBER  NOT NULL , 
     actividad_id_actividad NUMBER  NOT NULL , 
     fecha_cumplimiento     TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP  NOT NULL , 
     observaciones          VARCHAR2 (255) 
    ) 
;

COMMENT ON TABLE historial_cumplimiento IS 'Registro de actividades completadas'
;
CREATE INDEX idx_historial_actividad ON historial_cumplimiento 
    ( 
     actividad_id_actividad ASC 
    ) 
;

ALTER TABLE historial_cumplimiento 
    ADD CONSTRAINT historial_cumplimiento_PK PRIMARY KEY ( id_log ) ;

CREATE TABLE pictograma 
    ( 
     id_pictograma NUMBER  NOT NULL , 
     nombre_imagen VARCHAR2 (100)  NOT NULL , 
     url           VARCHAR2 (4000)  NOT NULL , 
     categoria     VARCHAR2 (50) 
    ) 
;

COMMENT ON TABLE pictograma IS 'Catálogo de pictogramas (ARASAAC y personalizados)'
;

ALTER TABLE pictograma 
    ADD CONSTRAINT pictograma_PK PRIMARY KEY ( id_pictograma ) ;

CREATE TABLE recompensa_disponible 
    ( 
     id_recompensa            NUMBER  NOT NULL , 
     estudiante_id_estudiante NUMBER  NOT NULL , 
     nombre_recompensa        VARCHAR2 (100)  NOT NULL , 
     recompensa_url           VARCHAR2 (4000) , 
     meta_estrellas           NUMBER DEFAULT 5  NOT NULL , 
     estado_logro             NUMBER (1) DEFAULT 0  NOT NULL , 
     fecha_logro              TIMESTAMP WITH TIME ZONE 
    ) 
;

ALTER TABLE recompensa_disponible 
    ADD 
    CHECK (estado_logro IN (0, 1)) 
;

COMMENT ON TABLE recompensa_disponible IS 'Recompensas canjeables con estrellas acumuladas'
;
CREATE INDEX idx_recompensa_estudiante ON recompensa_disponible 
    ( 
     estudiante_id_estudiante ASC 
    ) 
;

ALTER TABLE recompensa_disponible 
    ADD CONSTRAINT recompensa_disponible_PK PRIMARY KEY ( id_recompensa ) ;

CREATE TABLE registro_estrella_diaria 
    ( 
     id_registro              NUMBER  NOT NULL , 
     estudiante_id_estudiante NUMBER  NOT NULL , 
     fecha                    DATE DEFAULT TRUNC(SYSDATE)  NOT NULL , 
     estrellas_ganadas        NUMBER DEFAULT 0  NOT NULL 
    ) 
;

ALTER TABLE registro_estrella_diaria 
    ADD 
    CHECK (estrellas_ganadas >= 0) 
;

COMMENT ON TABLE registro_estrella_diaria IS 'Estrellas ganadas por estudiante por día'
;
CREATE INDEX idx_registro_estrella_fecha ON registro_estrella_diaria 
    ( 
     fecha ASC 
    ) 
;

ALTER TABLE registro_estrella_diaria 
    ADD CONSTRAINT registro_estrella_diaria_PK PRIMARY KEY ( id_registro ) ;

ALTER TABLE registro_estrella_diaria 
    ADD CONSTRAINT unq_estudiante_fecha UNIQUE ( estudiante_id_estudiante , fecha ) ;

CREATE TABLE rol 
    ( 
     id_rol     NUMBER  NOT NULL , 
     nombre_rol VARCHAR2 (50)  NOT NULL 
    ) 
;

COMMENT ON TABLE rol IS 'Roles de usuarios: Administrador, Profesor, Tutor/Apoderado, Estudiante'
;

ALTER TABLE rol 
    ADD CONSTRAINT rol_PK PRIMARY KEY ( id_rol ) ;

ALTER TABLE rol 
    ADD CONSTRAINT INDEX_1v2 UNIQUE ( nombre_rol ) ;

CREATE TABLE usuario 
    ( 
     id_usuario         NUMBER  NOT NULL , 
     rol_id_rol         NUMBER  NOT NULL , 
     nombre             VARCHAR2 (100)  NOT NULL , 
     email              VARCHAR2 (100)  NOT NULL , 
     password_hash      VARCHAR2 (255)  NOT NULL , 
     fecha_registro     TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP  NOT NULL , 
     reset_token        VARCHAR2 (100) , 
     reset_token_expiry TIMESTAMP WITH TIME ZONE , 
     curso_id_curso     NUMBER 
    ) 
;

COMMENT ON TABLE usuario IS 'Usuarios que inician sesión (todos los roles)'
;
CREATE INDEX idx_usuario_email ON usuario 
    ( 
     email ASC 
    ) 
;

ALTER TABLE usuario 
    ADD CONSTRAINT usuario_PK PRIMARY KEY ( id_usuario ) ;

ALTER TABLE usuario 
    ADD CONSTRAINT INDEX_1v3 UNIQUE ( email ) ;

ALTER TABLE usuario 
    ADD CONSTRAINT INDEX_2 UNIQUE ( reset_token ) ;

CREATE TABLE vinculacion_historial 
    ( 
     id_vinculo         NUMBER  NOT NULL , 
     usuario_id_usuario NUMBER  NOT NULL , 
     id_estudiante      NUMBER  NOT NULL , 
     rol_id_rol         NUMBER  NOT NULL , 
     fecha_inicio       TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP  NOT NULL , 
     fecha_termino      TIMESTAMP WITH TIME ZONE , 
     motivo_cambio      VARCHAR2 (255) 
    ) 
;

COMMENT ON TABLE vinculacion_historial IS 'Historial de vínculos entre adulto y estudiante (relación N:M)'
;
CREATE UNIQUE INDEX idx_un_vinculo_activo ON vinculacion_historial 
    ( 
     usuario_id_usuario ASC , 
     id_estudiante ASC 
    ) 
;
CREATE INDEX idx_vinculacion_usuario ON vinculacion_historial 
    ( 
     usuario_id_usuario ASC 
    ) 
;
CREATE INDEX idx_vinculacion_estudiante ON vinculacion_historial 
    ( 
     id_estudiante ASC 
    ) 
;

ALTER TABLE vinculacion_historial 
    ADD CONSTRAINT vinculacion_historial_PK PRIMARY KEY ( id_vinculo ) ;


ALTER TABLE actividad 
    ADD CONSTRAINT act_catalogo_FK FOREIGN KEY 
    ( 
     catalogo_actividad_id_catalogo
    ) 
    REFERENCES catalogo_actividad 
    ( 
     id_catalogo
    ) 
;

ALTER TABLE actividad 
    ADD CONSTRAINT actividad_estudiante_FK FOREIGN KEY 
    ( 
     estudiante_id_estudiante
    ) 
    REFERENCES estudiante 
    ( 
     id_estudiante
    ) 
    ON DELETE CASCADE 
;

ALTER TABLE actividad 
    ADD CONSTRAINT actividad_pictograma_FK FOREIGN KEY 
    ( 
     pictograma_id_pictograma
    ) 
    REFERENCES pictograma 
    ( 
     id_pictograma
    ) 
;

ALTER TABLE actividad 
    ADD CONSTRAINT actividad_usuario_FK FOREIGN KEY 
    ( 
     usuario_id_usuario
    ) 
    REFERENCES usuario 
    ( 
     id_usuario
    ) 
;


ALTER TABLE catalogo_actividad 
    ADD CONSTRAINT cat_act_picto_FK FOREIGN KEY 
    ( 
     pictograma_id_pictograma
    ) 
    REFERENCES pictograma 
    ( 
     id_pictograma
    ) 
;


ALTER TABLE configuracion_alerta 
    ADD CONSTRAINT conf_alerta_act_FK FOREIGN KEY 
    ( 
     actividad_id_actividad
    ) 
    REFERENCES actividad 
    ( 
     id_actividad
    ) 
    ON DELETE CASCADE 
;

ALTER TABLE estudiante 
    ADD CONSTRAINT estudiante_curso_FK FOREIGN KEY 
    ( 
     curso_id_curso
    ) 
    REFERENCES curso 
    ( 
     id_curso
    ) 
;

ALTER TABLE estudiante 
    ADD CONSTRAINT estudiante_usuario_FK FOREIGN KEY 
    ( 
     usuario_id_usuario
    ) 
    REFERENCES usuario 
    ( 
     id_usuario
    ) 
;


ALTER TABLE historial_cumplimiento 
    ADD CONSTRAINT hist_cump_act_FK FOREIGN KEY 
    ( 
     actividad_id_actividad
    ) 
    REFERENCES actividad 
    ( 
     id_actividad
    ) 
;


ALTER TABLE recompensa_disponible 
    ADD CONSTRAINT recomp_est_FK FOREIGN KEY 
    ( 
     estudiante_id_estudiante
    ) 
    REFERENCES estudiante 
    ( 
     id_estudiante
    ) 
    ON DELETE CASCADE 
;

 
ALTER TABLE registro_estrella_diaria 
    ADD CONSTRAINT reg_est_dia_est_FK FOREIGN KEY 
    ( 
     estudiante_id_estudiante
    ) 
    REFERENCES estudiante 
    ( 
     id_estudiante
    ) 
;

ALTER TABLE usuario 
    ADD CONSTRAINT usuario_curso_FK FOREIGN KEY 
    ( 
     curso_id_curso
    ) 
    REFERENCES curso 
    ( 
     id_curso
    ) 
;

ALTER TABLE usuario 
    ADD CONSTRAINT usuario_rol_FK FOREIGN KEY 
    ( 
     rol_id_rol
    ) 
    REFERENCES rol 
    ( 
     id_rol
    ) 
;


ALTER TABLE vinculacion_historial 
    ADD CONSTRAINT vinc_hist_est_FK FOREIGN KEY 
    ( 
     id_estudiante
    ) 
    REFERENCES estudiante 
    ( 
     id_estudiante
    ) 
;

ALTER TABLE vinculacion_historial 
    ADD CONSTRAINT vinculacion_historial_rol_FK FOREIGN KEY 
    ( 
     rol_id_rol
    ) 
    REFERENCES rol 
    ( 
     id_rol
    ) 
;

 
ALTER TABLE vinculacion_historial 
    ADD CONSTRAINT vinc_hist_usr_FK FOREIGN KEY 
    ( 
     usuario_id_usuario
    ) 
    REFERENCES usuario 
    ( 
     id_usuario
    ) 
;

CREATE SEQUENCE actividad_id_actividad_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER actividad_id_actividad_TRG 
BEFORE INSERT ON actividad 
FOR EACH ROW 
WHEN (NEW.id_actividad IS NULL) 
BEGIN 
    :NEW.id_actividad := actividad_id_actividad_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE catalogo_actividad_id_catalogo 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER catalogo_actividad_id_catalogo 
BEFORE INSERT ON catalogo_actividad 
FOR EACH ROW 
WHEN (NEW.id_catalogo IS NULL) 
BEGIN 
    :NEW.id_catalogo := catalogo_actividad_id_catalogo.NEXTVAL; 
END;
/

CREATE SEQUENCE configuracion_alerta_id_alerta 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER configuracion_alerta_id_alerta 
BEFORE INSERT ON configuracion_alerta 
FOR EACH ROW 
WHEN (NEW.id_alerta IS NULL) 
BEGIN 
    :NEW.id_alerta := configuracion_alerta_id_alerta.NEXTVAL; 
END;
/

CREATE SEQUENCE curso_id_curso_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER curso_id_curso_TRG 
BEFORE INSERT ON curso 
FOR EACH ROW 
WHEN (NEW.id_curso IS NULL) 
BEGIN 
    :NEW.id_curso := curso_id_curso_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE estudiante_id_estudiante_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER estudiante_id_estudiante_TRG 
BEFORE INSERT ON estudiante 
FOR EACH ROW 
WHEN (NEW.id_estudiante IS NULL) 
BEGIN 
    :NEW.id_estudiante := estudiante_id_estudiante_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE historial_cumplimiento_id_log 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER historial_cumplimiento_id_log 
BEFORE INSERT ON historial_cumplimiento 
FOR EACH ROW 
WHEN (NEW.id_log IS NULL) 
BEGIN 
    :NEW.id_log := historial_cumplimiento_id_log.NEXTVAL; 
END;
/

CREATE SEQUENCE pictograma_id_pictograma_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER pictograma_id_pictograma_TRG 
BEFORE INSERT ON pictograma 
FOR EACH ROW 
WHEN (NEW.id_pictograma IS NULL) 
BEGIN 
    :NEW.id_pictograma := pictograma_id_pictograma_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE recompensa_disponible_id_recom 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER recompensa_disponible_id_recom 
BEFORE INSERT ON recompensa_disponible 
FOR EACH ROW 
WHEN (NEW.id_recompensa IS NULL) 
BEGIN 
    :NEW.id_recompensa := recompensa_disponible_id_recom.NEXTVAL; 
END;
/

CREATE SEQUENCE registro_estrella_diaria_id_re 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER registro_estrella_diaria_id_re 
BEFORE INSERT ON registro_estrella_diaria 
FOR EACH ROW 
WHEN (NEW.id_registro IS NULL) 
BEGIN 
    :NEW.id_registro := registro_estrella_diaria_id_re.NEXTVAL; 
END;
/

CREATE SEQUENCE rol_id_rol_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER rol_id_rol_TRG 
BEFORE INSERT ON rol 
FOR EACH ROW 
WHEN (NEW.id_rol IS NULL) 
BEGIN 
    :NEW.id_rol := rol_id_rol_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE usuario_id_usuario_SEQ 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER usuario_id_usuario_TRG 
BEFORE INSERT ON usuario 
FOR EACH ROW 
WHEN (NEW.id_usuario IS NULL) 
BEGIN 
    :NEW.id_usuario := usuario_id_usuario_SEQ.NEXTVAL; 
END;
/

CREATE SEQUENCE vinculacion_historial_id_vincu 
START WITH 1 
    NOCACHE ;

CREATE OR REPLACE TRIGGER vinculacion_historial_id_vincu 
BEFORE INSERT ON vinculacion_historial 
FOR EACH ROW 
WHEN (NEW.id_vinculo IS NULL) 
BEGIN 
    :NEW.id_vinculo := vinculacion_historial_id_vincu.NEXTVAL; 
END;
/



-- Informe de Resumen de Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                            12
-- CREATE INDEX                            12
-- ALTER TABLE                             40
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                          12
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                         12
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   8
-- WARNINGS                                 0
