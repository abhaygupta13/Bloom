import { LightningElement,api,track,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class SalesOrderOtherChargesExport extends LightningElement {

@api recordId;
identifier = 'Salesordercharges';



renderedCallback(){
      this.dispatchEvent(new CloseActionScreenEvent());
}
  @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            
            this.recordId = currentPageReference.state.recordId;
           

        }
    }
     closeTheAction(event){
        
        this.dispatchEvent(new CloseActionScreenEvent());

    }
}