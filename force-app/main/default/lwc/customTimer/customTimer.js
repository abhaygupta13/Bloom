import { api, LightningElement, track, wire } from 'lwc';
import GetUnitBookTimeExtApprovStatus from "@salesforce/apex/OpportunityUnitSearchHandler.GetUnitBookTimeExtApprovStatus";
import UpdateUnitBookTimeExtApprovStatus from "@salesforce/apex/OpportunityUnitSearchHandler.UpdateUnitBookTimeExtApprovStatus";
import OppBookingExtendedTimerValue from '@salesforce/label/c.OppBookingExtendedTimerValue';

export default class CustomTimer extends LightningElement {

    pageVisisted = new Date(); // you should probably store this in a database/attach it to the session or AT LEAST in a cookie

    result;
    @api redirectTo;

    @api startFrom;
    @api maxIntervalNumbers;
    @api lockedUnit;
    lockedUnitList =[];
    OppBookingExtendedTimer;
    @api opportunityId;
    @track isExtraTimeAdded=false;
    showConfirmationButtons = true;
    alertMessage = "Do you want to complete active";
    showAlertMessage = false;
    intervalCount = 0;

    connectedCallback() {
    

 this.OppBookingExtendedTimer = OppBookingExtendedTimerValue;
 
        this.initializeTimer();

    }

    initializeTimer() {
        if (this.startFrom != 0 && this.startFrom != null & this.startFrom != undefined) {
            this.timer(Number(this.startFrom));
        } else {
            this.timer(8);
        }
    }

    timer(duration) {
        duration = duration * 60;

        var timer = duration, minutes, seconds;
        const interval = setInterval(() => {
            minutes = parseInt(timer / 60, 10);
            seconds = parseInt(timer % 60, 10);

            minutes = minutes < 10 ? "0" + minutes : minutes;
            seconds = seconds < 10 ? "0" + seconds : seconds;

            this.result = minutes + ":" + seconds;

            if(!this.isExtraTimeAdded){
            if (timer === 30) {
               //   alert('before 30 second'+this.isExtraTimeAdded);
              //  alert('before 10 seconds')
                GetUnitBookTimeExtApprovStatus({ OpportunityId: this.opportunityId })
                    .then(result => {
                   let  approvalResult = result;
                        
                        if (approvalResult == 'Approved') {
                             const approveEvent = new CustomEvent('approved', { detail: true });
                            this.dispatchEvent(approveEvent);
                            // Extend timer by 5 minutes
                            timer += this.OppBookingExtendedTimer * 60;
                         this.isExtraTimeAdded=true;
                            UpdateUnitBookTimeExtApprovStatus({OpportunityId: this.opportunityId,TobeInCreasedLockedUnits:this.lockedUnit,increasedTime:this.OppBookingExtendedTimer,approvalResult:approvalResult})
                            .then(result=>{
                                this.result =result;
                            }).then(error=>{
                                this.error = error;
                            })
                        }else if(approvalResult=='Rejected'){
                           
                             UpdateUnitBookTimeExtApprovStatus({OpportunityId: this.opportunityId,TobeInCreasedLockedUnits:this.lockedUnit,increasedTime:this.OppBookingExtendedTimer,approvalResult:approvalResult})
                            .then(result=>{
                                this.result =result;
                                 this.isExtraTimeAdded=true;
                                
                            }).then(error=>{
                                this.error = error;
                            })
                        }
                    }).catch(error => {
                        this.error = error;
                    })

         
            }
            }
             if(!this.isExtraTimeAdded){
            if (timer === 10) {
           
                GetUnitBookTimeExtApprovStatus({ OpportunityId: this.opportunityId })
                    .then(result => {
                   let  approvalResult = result;
                        
                        if (approvalResult == 'Approved') {
                             const approveEvent = new CustomEvent('approved', { detail: true });
                            this.dispatchEvent(approveEvent);
                            // Extend timer by 5 minutes
                            timer += this.OppBookingExtendedTimer * 60;
                         this.isExtraTimeAdded=true;
                            UpdateUnitBookTimeExtApprovStatus({OpportunityId: this.opportunityId,TobeInCreasedLockedUnits:this.lockedUnit,increasedTime:this.OppBookingExtendedTimer,approvalResult:approvalResult})
                            .then(result=>{
                                this.result =result;
                            }).then(error=>{
                                this.error = error;
                            })
                        }else if(approvalResult=='Rejected'){
                           
                             UpdateUnitBookTimeExtApprovStatus({OpportunityId: this.opportunityId,TobeInCreasedLockedUnits:this.lockedUnit,increasedTime:this.OppBookingExtendedTimer,approvalResult:approvalResult})
                            .then(result=>{
                                this.result =result;
                                 this.isExtraTimeAdded=true;
                                
                            }).then(error=>{
                                this.error = error;
                            })
                        }
                    }).catch(error => {
                        this.error = error;
                    })

         
            }
            }

           
            if (timer <= 0) {
                
                clearInterval(interval); // Stop the interval
                this.intervalCount += 1;

                if (this.maxIntervalNumbers == 0 || this.maxIntervalNumbers == undefined || this.maxIntervalNumbers == null) {
                    this.maxIntervalNumbers = 3;
                }

                if (this.intervalCount == parseInt(this.maxIntervalNumbers)) {
                    this.showAlertMessage = true;
                } else {

                    window.location.reload(); // Refresh the page
                }
            }else {
        timer--; // Decrement timer here
    } 
            
        }, 1000);
    }



   

  
}