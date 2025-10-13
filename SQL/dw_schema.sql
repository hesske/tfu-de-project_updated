CREATE TABLE IF NOT EXISTS "factJobSkills" (
        "ID"    INTEGER,
        "ONET_SOC_CODE" TEXT NOT NULL,
        "Skill_Element" INTEGER,
        "Skill_Name"    TEXT,
        "Tech_Skill_Key"        INTEGER,
        "Tech_Skill_Name"       TEXT,
        "Job_Title"     INTEGER,
        "created_at"    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY("ID")
);
CREATE TABLE IF NOT EXISTS "dimTechSkills" (
	"ONET_SOC_Code" TEXT,
  	"Example" TEXT,
  	"Commodity_Code" INTEGER,
  	"Commodity_Title" TEXT,
 	"Hot_Tech" TEXT,
  	"In_Demand" TEXT,
  	"created_at" TIMESTAMP
);
CREATE TABLE IF NOT EXISTS "dimJobInfo" (
	"ONET_SOC_Code" TEXT,
  	"Title" TEXT,
  	"Description" TEXT,
  	"created_at" TIMESTAMP
);
CREATE TABLE IF NOT EXISTS "dimSkills" (
	"ONET_SOC_Code" TEXT,
 	"Element_ID" TEXT,
  	"Skill" TEXT,
  	"Scale_ID" TEXT,
  	"Data Value" REAL,
  	"created_at" TIMESTAMP
);