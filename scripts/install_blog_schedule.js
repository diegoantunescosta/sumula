#!/usr/bin/env node
'use strict';
const fs=require('node:fs');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..'),marker='# SUMULA_DAILY_BLOG';
const quote=s=>"'"+s.replace(/'/g,"'\\''")+"'";
const data=path.join(root,'data');fs.mkdirSync(data,{recursive:true});
const log=path.join(data,'blog-daily.log');fs.closeSync(fs.openSync(log,'a',0o600));
let current='';try{current=execFileSync('crontab',['-l'],{encoding:'utf8',stdio:['ignore','pipe','pipe']});}catch(e){if(e.status!==1)throw e;}
const keep=current.split('\n').filter(line=>line&&!line.includes(marker));
const command=`*/15 * * * * PATH=${quote(path.dirname(process.execPath)+':/usr/local/bin:/usr/bin:/bin')} ${quote(process.execPath)} ${quote(path.join(root,'scripts/blog_daily.js'))} >> ${quote(log)} 2>&1 ${marker}`;
execFileSync('crontab',['-'],{input:keep.concat(command).join('\n')+'\n'});
console.log('Agendamento instalado: verificação a cada 15 minutos; publicação após 09:00 America/Sao_Paulo, até um artigo por dia.');
