INSERT INTO factJobSkills (
    ONET_SOC_Code,
    Skill_Element,
    Skill_Name,
    Tech_Skill_Key,
    Tech_Skill_Name,
    Job_Title,
    created_at
)
SELECT
    s.ONET_SOC_Code,
    s.Element_ID,
    s.Skill,
    111111 as Tech_Skill_Key,
    "NA" as Tech_Skill_Name,
    j.Title,
    CURRENT_TIMESTAMP
FROM
    dimSkills s
LEFT JOIN
    dimJobInfo j ON s.ONET_SOC_Code = j.ONET_SOC_Code


UNION

SELECT
    t.ONET_SOC_Code,
    222222 as Element_ID,
    "NA" as Skill,
    t.Commodity_Code,
    t.Commodity_Title,
    j.Title,
    CURRENT_TIMESTAMP
FROM
    dimTechSkills t
LEFT JOIN
    dimJobInfo j ON t.ONET_SOC_Code = j.ONET_SOC_Code