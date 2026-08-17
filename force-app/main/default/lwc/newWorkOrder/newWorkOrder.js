import { LightningElement, api, wire,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import getRelatedUnits from '@salesforce/apex/UnitDataTableController.getRelatedUnits';

const columns = [
    { label: 'Name', fieldName: 'Name'},
    { label: 'Project Name', fieldName: 'ProjectName__c' },
    { label: 'Unit Type', fieldName: 'UnitType__c' },
    { label: 'Sold Date', fieldName: 'Sold_date__c', type: 'date' },
    { label: 'DLP Start Date', fieldName: 'DLP_Start_Date__c', type: 'date' },
    { label: 'DLP_End_Date__c', fieldName: 'DLP_End_Date__c', type: 'date' },
    {
        type: 'button',
        typeAttributes: {
            label: 'New WorkOrder',
            name: 'New_WorkOrder',
            title: 'Perform Action',
            disabled: false,
            value: 'action'
        }
    }
];

export default class NewWorkOrder extends NavigationMixin(LightningElement) {

    @api recordId;
    @track units=[];
    @wire(CurrentPageReference) currentPageReference;

    columns = columns;

    @wire(getRelatedUnits, { accountId: '$recordId' })
    wiredUnits({ error, data }) {
        if (data) {
            console.log('data:',data);
            let unit=[];
            for(let i = 0;i<data.length;i++){
                unit.push(data[i].Unit__r)
            }
            this.units = unit;
        } else if (error) {
            console.log('error:',error);
        }
    }

    connectedCallback() {
        this.recordId = this.currentPageReference.attributes.recordId;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'New_WorkOrder':
                this.newWorkOrder(row);
                break;
            default:
        }
    }

    newWorkOrder(row) {

        console.log('Custom action on: ', row);
        const defaultValues = encodeDefaultFieldValues({
            AccountId: this.recordId,
            Unit__c: row.Id,
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WorkOrder',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
            },
        });
    }
}