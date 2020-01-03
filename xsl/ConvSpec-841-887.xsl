<?xml version='1.0'?>
<xsl:stylesheet version="1.0"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
                xmlns:bflc="http://id.loc.gov/ontologies/bflc/"
                xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="xsl marc">

  <!--
      Conversion specs for 841-887
  -->

  <xsl:template match="marc:datafield[@tag='856']" mode="work">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:apply-templates select="." mode="work856">
      <xsl:with-param name="recordid" select="$recordid"/>
      <xsl:with-param name="serialization" select="$serialization"/>
      <xsl:with-param name="pTagOrd" select="position()"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- 859 is a local field at LoC -->
  <xsl:template match="marc:datafield[@tag='859']" mode="work">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:if test="$localfields">
      <xsl:apply-templates select="." mode="work856">
        <xsl:with-param name="recordid" select="$recordid"/>
        <xsl:with-param name="serialization" select="$serialization"/>
        <xsl:with-param name="pTagOrd" select="position()"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield" mode="work856">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:param name="pTagOrd" select="position()"/>
    <!-- If ind2 is #, 0, 1, or 8 and the Instance does not have the class of Electronic, create a new Instance -->
    <!-- 
        kefo note - 3 Jan 2020
        Added this variable and see the last line of the 'test' of the following
        'if' statement, which I also added.  This ensures that a new Instance 
        is not created for poorly cataloged stuff.  In this case, a "table of contents"
        that has been identified as a different version of the resource (ind2=1).
        There is a corresponding bit of code that inserts the table of contents
        where it should be, in the instance.  See note further down.
    -->
    <xsl:variable name="uLabelTest">
        <xsl:variable name="uLabelCombined">
            <xsl:apply-templates mode="concat-nodes-space" select="marc:subfield[@code='z' or @code='y' or @code='3']"/>
        </xsl:variable>
        <xsl:call-template name="simpleNormalization">
            <xsl:with-param name="sString"><xsl:value-of select="$uLabelCombined"/></xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="marc:subfield[@code='u'] and
                  (@ind2=' ' or @ind2='0' or @ind2='1' or @ind2='8') and
                  (substring(../marc:leader,7,1) != 'm' and
                  substring(../marc:controlfield[@tag='008'],24,1) != 'o' and
                  substring(../marc:controlfield[@tag='008'],24,1) != 's') and
                  contains($uLabelTest, 'tableofcontents') = false()">
      <xsl:variable name="vInstanceUri"><xsl:value-of select="$recordid"/>#Instance<xsl:value-of select="@tag"/>-<xsl:value-of select="$pTagOrd"/></xsl:variable>
      <!-- <xsl:variable name="vItemUri"><xsl:value-of select="$recordid"/>#Item<xsl:value-of select="@tag"/>-<xsl:value-of select="$pTagOrd"/></xsl:variable> -->
      <xsl:choose>
        <xsl:when test="$serialization = 'rdfxml'">
          <bf:hasInstance>
            <bf:Instance>
              <xsl:attribute name="rdf:about"><xsl:value-of select="$vInstanceUri"/></xsl:attribute>
              <rdf:type>
                <xsl:attribute name="rdf:resource"><xsl:value-of select="concat($bf,'Electronic')"/></xsl:attribute>
              </rdf:type>
              <!--
                kefo note - 30 Dec 2019
                When dealing with an 856, it's not clear what a good "label" would be.
                It's probably not the "title" of the Work/Expression, but I'm not 
                going to wade into this water right now.
                
                kefo note - 3 Jan 2020
                New decade.  Going to deal with the titles here.
              -->
              <!--
              <xsl:if test="../marc:datafield[@tag='245']">
                <bf:title>
                  <xsl:apply-templates mode="title245" select="../marc:datafield[@tag='245']">
                    <xsl:with-param name="serialization" select="$serialization"/>
                    <xsl:with-param name="label">
                      <xsl:apply-templates mode="concat-nodes-space"
                                           select="../marc:datafield[@tag='245']/marc:subfield[@code='a' or
                                                   @code='b' or
                                                   @code='f' or 
                                                   @code='g' or
                                                   @code='k' or
                                                   @code='n' or
                                                   @code='p' or
                                                   @code='s']"/>
                    </xsl:with-param>
                  </xsl:apply-templates>
                </bf:title>
              </xsl:if>
              -->
              <xsl:variable name="uLabelCombined">
                <xsl:apply-templates mode="concat-nodes-delimited" select="marc:subfield[@code='z' or @code='y' or @code='3']"/>
              </xsl:variable>
              <xsl:if test="$uLabelCombined != ''">
                  <bf:title>
                      <bf:Title>
                          <rdfs:label><xsl:value-of select="$uLabelCombined"/></rdfs:label>
                          <bf:mainTitle><xsl:value-of select="$uLabelCombined"/></bf:mainTitle>
                      </bf:Title>
                  </bf:title>
              </xsl:if>
              <!--
                kefo note - 3 January 2020
                Now I'm really going to shake things up.
                Commented out the below and replaced it with the for-each. 
                Also commented out the variable declaration above for vItemUri
              -->
              <!--
              <bf:hasItem>
                <bf:Item>
                  <xsl:attribute name="rdf:about"><xsl:value-of select="$vItemUri"/></xsl:attribute>
                  <xsl:apply-templates select="." mode="locator856">
                    <xsl:with-param name="serialization" select="$serialization"/>
                    <xsl:with-param name="pProp">bf:electronicLocator</xsl:with-param>
                    <xsl:with-param name="pLocatorProp">bflc:target</xsl:with-param>
                  </xsl:apply-templates>
                  <bf:itemOf>
                    <xsl:attribute name="rdf:resource"><xsl:value-of select="$vInstanceUri"/></xsl:attribute>
                  </bf:itemOf>
                </bf:Item>
              </bf:hasItem>
              -->
              <xsl:for-each select="marc:subfield[@code='u']">
                <xsl:variable name="vItemUri"><xsl:value-of select="$recordid"/>#Item<xsl:value-of select="../@tag"/>-<xsl:value-of select="$pTagOrd"/>-<xsl:value-of select="position()"/></xsl:variable>
                <bf:hasItem>
                    <bf:Item>
                        <xsl:attribute name="rdf:about"><xsl:value-of select="$vItemUri"/></xsl:attribute>
                        <rdfs:label><xsl:value-of select="."/></rdfs:label>
                        <bf:electronicLocator>
                            <xsl:attribute name="rdf:resource"><xsl:value-of select="."/></xsl:attribute>
                        </bf:electronicLocator>
                        <bf:itemOf>
                            <xsl:attribute name="rdf:resource"><xsl:value-of select="$vInstanceUri"/></xsl:attribute>
                        </bf:itemOf>
                    </bf:Item>
                </bf:hasItem>
              </xsl:for-each>
              <bf:instanceOf>
                <xsl:attribute name="rdf:resource"><xsl:value-of select="$recordid"/>#Work</xsl:attribute>
              </bf:instanceOf>
            </bf:Instance>
          </bf:hasInstance>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='856']" mode="instance">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:apply-templates select="." mode="instance856">
      <xsl:with-param name="recordid" select="$recordid"/>
      <xsl:with-param name="serialization" select="$serialization"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- 859 is a local field at LoC -->
  <xsl:template match="marc:datafield[@tag='859']" mode="instance">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:if test="$localfields">
      <xsl:apply-templates select="." mode="instance856">
        <xsl:with-param name="recordid" select="$recordid"/>
        <xsl:with-param name="serialization" select="$serialization"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield" mode="instance856">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
            
    <xsl:if test="marc:subfield[@code='u'] and @ind2='2'">
      <xsl:choose>
        <xsl:when test="$serialization = 'rdfxml'">
          <xsl:apply-templates select="." mode="locator856">
            <xsl:with-param name="serialization" select="$serialization"/>
            <xsl:with-param name="pProp">bf:supplementaryContent</xsl:with-param>
            <xsl:with-param name="pLocatorProp">bflc:locator</xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    <!-- 
        kefo note - 3 Jan 2020
        This looks for things like "table of contents" in the 856 wrongly coded 
        as "version of resource" (aka @ind2=1).
        It will output it as supplementary content on the Instance.  Probably should 
        be "tableOfContents" but whatever for now.  Then again, may be not.  
        At least will produce a SupplementaryContent that is consistent.
    -->
    <xsl:if test="marc:subfield[@code='u'] and @ind2='1'">
        <xsl:variable name="uLabelTest">
            <xsl:variable name="uLabelCombined">
                <xsl:apply-templates mode="concat-nodes-space" select="marc:subfield[@code='z' or @code='y' or @code='3']"/>
            </xsl:variable>
            <xsl:call-template name="simpleNormalization">
                <xsl:with-param name="sString"><xsl:value-of select="$uLabelCombined"/></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$uLabelTest != '' and contains($uLabelTest, 'tableofcontents')">
            <xsl:choose>
                <xsl:when test="$serialization = 'rdfxml'">
                  <xsl:apply-templates select="." mode="locator856">
                    <xsl:with-param name="serialization" select="$serialization"/>
                    <xsl:with-param name="pProp">bf:supplementaryContent</xsl:with-param>
                    <xsl:with-param name="pLocatorProp">bflc:locator</xsl:with-param>
                  </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:if>
  </xsl:template>
          
  <xsl:template match="marc:datafield[@tag='856']" mode="hasItem">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:apply-templates select="." mode="hasItem856">
      <xsl:with-param name="recordid" select="$recordid"/>
      <xsl:with-param name="serialization" select="$serialization"/>
      <xsl:with-param name="pTagOrd" select="position()"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- 859 is a local field at LoC -->
  <xsl:template match="marc:datafield[@tag='859']" mode="hasItem">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:if test="$localfields">
      <xsl:apply-templates select="." mode="hasItem856">
        <xsl:with-param name="recordid" select="$recordid"/>
        <xsl:with-param name="serialization" select="$serialization"/>
        <xsl:with-param name="pTagOrd" select="position()"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield" mode="hasItem856">
    <xsl:param name="recordid"/>
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:param name="pTagOrd" select="position()"/>
    <!-- If ind2 is #, 0, 1, or 8 and the Instance has the class of Electronic, add an Item to the Instance -->
    <xsl:if test="marc:subfield[@code='u'] and
                  (@ind2=' ' or @ind2='0' or @ind2='1' or @ind2='8') and
                  (substring(../marc:leader,7,1) = 'm' or
                  substring(../marc:controlfield[@tag='008'],24,1) = 'o' or
                  substring(../marc:controlfield[@tag='008'],24,1) = 's')">
        <xsl:variable name="vItemUri"><xsl:value-of select="$recordid"/>#Item<xsl:value-of select="@tag"/>-<xsl:value-of select="$pTagOrd"/></xsl:variable>
        <xsl:choose>
            <xsl:when test="$serialization = 'rdfxml'">
              <bf:hasItem>
                <bf:Item>
                  <xsl:attribute name="rdf:about"><xsl:value-of select="$vItemUri"/></xsl:attribute>
                  <xsl:apply-templates select="." mode="locator856">
                    <xsl:with-param name="serialization" select="$serialization"/>
                    <xsl:with-param name="pProp">bf:electronicLocator</xsl:with-param>
                    <xsl:with-param name="pLocatorProp">bflc:locator</xsl:with-param>
                  </xsl:apply-templates>
                  <bf:itemOf>
                    <xsl:attribute name="rdf:resource"><xsl:value-of select="$recordid"/>#Instance</xsl:attribute>
                  </bf:itemOf>
                </bf:Item>
              </bf:hasItem>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield" mode="locator856">
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:param name="pProp" select="'bf:electronicLocator'"/>
    <xsl:param name="pLocatorProp" select="'bflc:locator'"/>
    <xsl:choose>
      <xsl:when test="$serialization='rdfxml'">
        <xsl:for-each select="marc:subfield[@code='u']">
          <xsl:element name="{$pProp}">
            <xsl:choose>
              <xsl:when test="../marc:subfield[@code='z' or @code='y' or @code='3']">
                <rdfs:Resource>
                  <xsl:element name="{$pLocatorProp}">
                    <xsl:attribute name="rdf:resource"><xsl:value-of select="."/></xsl:attribute>
                  </xsl:element>
                  <xsl:for-each select="../marc:subfield[@code='z' or @code='y' or @code='3']">
                    <bf:note>
                      <bf:Note>
                        <rdfs:label><xsl:value-of select="."/></rdfs:label>
                      </bf:Note>
                    </bf:note>
                  </xsl:for-each>
                </rdfs:Resource>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="rdf:resource"><xsl:value-of select="."/></xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:element>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  
</xsl:stylesheet>
