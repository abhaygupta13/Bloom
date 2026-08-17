import { track, api, LightningElement } from 'lwc';
import addFilesonRecord from '@salesforce/apex/CustomDocManageController.addFilesonRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class CameraCapture extends LightningElement {
  videoElement;
  canvasElement;
  cameraCaptureRef;
  @track callOnce = true;
  capturedImageFile;
  @api imageDocumentId;
  @track imgData;
  showLoading=false;

  renderedCallback() {
      
    this.videoElement = this.template.querySelector('.videoElement');
    this.canvasElement = this.template.querySelector('.canvas');
    if (this.callOnce)
      this.initCamera();
  }

  async initCamera() {
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {

        this.videoElement.srcObject = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
        this.callOnce = false;
      } catch (error) {
        console.error('Error accessing the camera: ', JSON.stringify(error));
      }
    } else {
      console.error('getUserMedia is not supported in this browser');
    }
  }
  /*dataURLtoBlob(dataURL) {
    const byteString = atob(dataURL.split(',')[1]);
    const mimeString = dataURL.split(',')[0].split(':')[1].split(';')[0];
    const ab = new ArrayBuffer(byteString.length);
    const ia = new Uint8Array(ab);
    for (let i = 0; i < byteString.length; i++) {
      ia[i] = byteString.charCodeAt(i);
    }
    return new Blob([ab], { type: mimeString });
  }*/


  captureImage() {
    if (this.videoElement && this.videoElement.srcObject !== null) {
     
      this.canvasElement.height = this.videoElement.videoHeight;
      this.canvasElement.width = this.videoElement.videoWidth;
      const context = this.canvasElement.getContext('2d');
      context.drawImage(this.videoElement, 0, 0, this.canvasElement.width, this.canvasElement.height);
      const imageData = this.canvasElement.toDataURL('image/png');
      this.imgData = imageData;
      const saveBtn = this.template.querySelector('.saveBtn');
      saveBtn.classList.remove('slds-hide');
      saveBtn.classList.add('slds-show');

      const imageElement = this.template.querySelector('.imageElement');
      imageElement.setAttribute('src', imageData);
      imageElement.classList.add('slds-show');
      imageElement.classList.remove('slds-hide');

    }
  }




  @api stopCamera() {
    const video = this.template.querySelector(".videoElement");
    video.srcObject.getTracks().forEach((track) => track.stop());
    video.srcObject = null;
    this.hideImageElement();
  }

  hideImageElement() {
    const imageElement = this.template.querySelector('.imageElement');
    imageElement.setAttribute('src', "");
    imageElement.classList.add('slds-hide');
    imageElement.classList.remove('slds-show');
  }
  handleSave(event) {
    
    this.showLoading=true;
    let obj = new Object();
    obj.sobjectType = 'Document__c';
    obj.Id = this.imageDocumentId;
  //alert(JSON.stringify(obj));
    const base64 = this.imgData.split(',')[1];
    addFilesonRecord({ base64: base64, filename: 'CameraImage.png', documentObj: obj })
      .then(result => {
         this.showLoading=false;
        const toast = new ShowToastEvent({
          title: 'Success',
          message: 'Image has been uploaded',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(toast);

        this.stopCamera();
        this.dispatchEvent(new CustomEvent('handlesuccess', {
          detail: {}
        }));


      }).catch(error => {
        this.error = error;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'error',
            message: 'this.error!',
            variant: 'error'
          })
        );
      })

  }
  closePopupWindow(event){
    this.stopCamera();
    this.dispatchEvent(new CustomEvent('handleclose', {
          detail: {}
        }));

  }
}