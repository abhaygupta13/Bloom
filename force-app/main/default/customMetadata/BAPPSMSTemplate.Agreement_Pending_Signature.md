<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Agreement Pending Signature</label>
    <protected>false</protected>
    <values>
        <field>IsActive__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Message_Body__c</field>
        <value xsi:type="xsd:string">Hi, this is a reminder that your brokerage agreement for application ref {{Application_Number}} is still pending for signature.

The DocuSign was sent on {{Initiation_Date}}. You have {{Days_Remaining}} day(s) left before the application is automatically cancelled.

Please check your email inbox to complete the signing.

Bloom Broker Management</value>
    </values>
    <values>
        <field>Template_Name__c</field>
        <value xsi:type="xsd:string">Agreement Pending Signature</value>
    </values>
</CustomMetadata>
