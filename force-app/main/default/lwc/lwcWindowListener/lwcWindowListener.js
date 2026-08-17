import { LightningElement } from 'lwc';

export default class lwcWindowListener extends LightningElement {
    vfHost = window.location.origin + "/apex/LightningConnectorBridge";
    connectedCallback() {
        /*
        window.addEventListener('keydown', (e) => {
            //console.log(`window listener key press :${e.keyCode} ctrlKey : ${e.ctrlKey} true : ${ (e.keyCode === 81 && e.ctrlKey ) }`);
            console.log(`window listener keyCode :${e.keyCode} ctrlKey : ${e.ctrlKey} altKey : ${e.altKey} shiftKey : ${e.shiftKey} event :`,e);
            this.template.querySelector('iframe').contentWindow.postMessage({type:"keypress",keyCode:e.keyCode,ctrlKey:e.ctrlKey,altKey:e.altKey,shiftKey : e.shiftKey,metaKey:e.metaKey},'*');         
        });
*/
        let unloadEvent = (e) => {
            console.log("unloadEvent : ", e);
            let confirmationMessage = "Warning: You will be set Not Ready on the WDE.";
            //   this.template.querySelector('iframe').contentWindow.postMessage({type :"onbeforeunload"}, '*');
            this.template.querySelector('iframe').contentWindow.postMessage({ type: "onbeforeunload" }, '*');
            (e || window.event).returnValue = confirmationMessage; //Gecko + IE
            return confirmationMessage; //Webkit, Safari, Chrome etc.
        };
        window.addEventListener("beforeunload", unloadEvent);
    }
}