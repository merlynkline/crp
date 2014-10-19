-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun Oct 19 21:25:06 2014
-- 
;
--
-- Table: enquiry.
--
CREATE TABLE "enquiry" (
  "id" serial NOT NULL,
  "email" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "enquiry_email_key" UNIQUE ("email")
);

;
