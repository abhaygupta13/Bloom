/**
 * @author Prashant Sahu
 * @date 16 Mar 2026
 * @description Runtime SLA Calculation Progress Bar for Task
 */
import { LightningElement, api, wire } from 'lwc';
import calculateSlaPercentage from '@salesforce/apex/TaskController.calculateSlaPercentage';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Task.AssignedDateTime__c',
    'Task.CompletedDateTime',
    'Task.BusinessHours__c',
    'Task.SLAHours__c',  
];

export default class SlaCalculationAction extends LightningElement {
    @api recordId;
    percentage = 0;
    statusClass = '';
    statusMessage = '';
    wiredSlaResult;
    timer;

    /* Detect record changes */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    taskRecord() {
        if(this.wiredSlaResult){
            refreshApex(this.wiredSlaResult);
        }
    }

    /* SLA Calculation Apex */
    @wire(calculateSlaPercentage, { taskId: '$recordId' })
    wiredSla(result){
        this.wiredSlaResult = result;
        if(result.data !== undefined){
            let percent = Math.floor(result.data);
            if(percent > 100){
                percent = 100;
            }
            this.percentage = percent;
            if(percent <= 50){
                this.statusClass = "green";
                this.statusMessage = "🟢 Within SLA";
            }
            else if(percent < 100){
                this.statusClass = "yellow";
                this.statusMessage = "🟡 Approaching SLA Limit";
            }
            else{
                this.statusClass = "red";
                this.statusMessage = "🔴 SLA Breached";
            }
        }
        else if(result.error){
            console.error(result.error);
        }
    }
    /* AUTO REFRESH EVERY 5 MIN */
    connectedCallback(){
        this.timer = setInterval(() => {
            if(this.wiredSlaResult){
                refreshApex(this.wiredSlaResult);
            }
        }, 5 * 60 * 1000); // 5 minutes
    }

    /* CLEANUP TIMER */
    disconnectedCallback(){
        if(this.timer){
            clearInterval(this.timer);
        }
    }
    get progressStyle(){
        return `width:${this.percentage}%`;
    }
    get progressBarClass(){
        return `progress-bar ${this.statusClass}`;
    }
}