const fs=require('fs'),vm=require('vm'),assert=require('assert');
const source=fs.readFileSync('web_shell.html','utf8').split('<script>')[1].split('</script>')[0].replace('$GODOT_CONFIG','{}').replace('$GODOT_THREADS_ENABLED','false');
function fixture(missing=[],reject=false){
 const els=Object.fromEntries(['boot','phase','detail','progress','retry','canvas'].map(k=>[k,{hidden:k==='retry',textContent:'',handlers:{},addEventListener(n,f){this.handlers[n]=f},removeAttribute(n){delete this[n]}}]));let opts,yes,no,interval,now=0;const handlers={};
 class Engine{static getMissingFeatures(){return missing}startGame(o){opts=o;return {then(a,b){yes=a;no=b;}}}}
 const ctx={document:{getElementById:k=>els[k]},window:{addEventListener:(k,f)=>handlers[k]=f},Engine,Date:{now:()=>now},setInterval:f=>(interval=f,1),clearInterval:()=>{},location:{reload:()=>{}},console:{error:()=>{}}};
 vm.runInNewContext(source,ctx);return {els,get opts(){return opts},success:()=>yes(),failure:()=>no(new Error('WASM failed')),tick:()=>{now=46000;interval()},handlers};
}
let f=fixture();f.opts.onProgress(50,100);assert.match(f.els.phase.textContent,/50%/);f.opts.onProgress(100,100);assert.match(f.els.phase.textContent,/起動/);assert.strictEqual(f.els.progress.value,undefined);f.tick();assert.equal(f.els.retry.hidden,false);f.success();assert.equal(f.els.boot.hidden,true);
f=fixture(['WebGL2']);assert.match(f.els.detail.textContent,/WebGL2/);assert.equal(f.els.retry.hidden,false);
f=fixture();f.failure();assert.match(f.els.detail.textContent,/WASM failed/);assert.equal(f.els.boot.hidden,false);
f=fixture();f.success();f.els.canvas.handlers.webglcontextlost({preventDefault(){}});assert.equal(f.els.boot.hidden,false);assert.match(f.els.detail.textContent,/メモリ/);
f=fixture();f.handlers.unhandledrejection({reason:'init error'});assert.match(f.els.detail.textContent,/init error/);
console.log('WEB LOADER RESULT: 0 failures (download, initialization, slow boot, success, missing feature, rejection, context loss)');
