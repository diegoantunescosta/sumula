#!/usr/bin/env node
'use strict';
// Roda no host: a autenticação do Codex nunca entra na imagem ou no app público.
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawn,execFileSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'..');
function cli(command,input,extra=[]){
 return JSON.parse(execFileSync('docker',['compose','exec','-T','api','node','src/blog_cli.js',command,...extra],{
  cwd:ROOT,input:input?JSON.stringify(input):undefined,encoding:'utf8',timeout:180000,maxBuffer:1024*1024,stdio:['pipe','pipe','pipe'],
 }));
}
function findCodex(){
 if(process.env.CODEX_BIN&&fs.existsSync(process.env.CODEX_BIN))return process.env.CODEX_BIN;
 try{return execFileSync('which',['codex'],{encoding:'utf8'}).trim();}catch{}
 const extensions=path.join(os.homedir(),'.vscode-server/extensions');
 for(const entry of fs.readdirSync(extensions).filter(n=>n.startsWith('openai.chatgpt-')).sort().reverse()){
  const candidate=path.join(extensions,entry,'bin/linux-x86_64/codex');if(fs.existsSync(candidate))return candidate;
 }
 throw new Error('Codex CLI não encontrado. Configure CODEX_BIN e autentique com codex login.');
}
// Geração via OpenRouter (modelo gratuito "openrouter/free"); a chave fica no .env da Súmula, fora do git.
function openRouterKey(){
 if(process.env.OPENROUTER_API_KEY)return process.env.OPENROUTER_API_KEY;
 const env=fs.readFileSync(path.join(ROOT,'.env'),'utf8');
 const m=env.match(/^OPENROUTER_API_KEY=(.*)$/m);
 if(!m)throw new Error('OPENROUTER_API_KEY ausente no .env');
 return m[1].trim().replace(/^["']|["']$/g,'');
}
function extractJson(raw,name){
 try{return JSON.parse(raw);}catch{}
 const fenced=raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
 if(fenced){try{return JSON.parse(fenced[1]);}catch{}}
 const a=raw.indexOf('{'),b=raw.lastIndexOf('}');
 if(a>=0&&b>a){try{return JSON.parse(raw.slice(a,b+1));}catch{}}
 throw new Error(`Etapa ${name} não retornou JSON válido.`);
}
// Modelos gratuitos fixos (com fallback). O "openrouter/free" sorteava um modelo
// diferente a cada chamada, sem acesso à web, e escritor/revisor inventavam ou
// recusavam fatos ao acaso. Sobrescreva com SUMULA_BLOG_MODELS=a,b,c.
const MODELS=(process.env.SUMULA_BLOG_MODELS||'nvidia/nemotron-3-ultra-550b-a55b:free,google/gemma-4-31b-it:free,openrouter/free').split(',').map(s=>s.trim()).filter(Boolean);
const {DOMAINS,safeSource,validatePost}=require('../src/blog_validation');
// A revisão só vale de modelos grandes: sem o sorteio do openrouter/free, que
// pode cair num modelo fraco e aprovar o que os outros recusaram.
const REVIEW_MODELS=(process.env.SUMULA_REVIEW_MODELS||'nvidia/nemotron-3-ultra-550b-a55b:free,google/gemma-4-31b-it:free').split(',').map(s=>s.trim()).filter(Boolean);
async function ask(dir,name,prompt,schemaText,temperature=0.4){
 const models=name.startsWith('review')?REVIEW_MODELS:MODELS;
 // Modelos gratuitos às vezes devolvem texto vazio, truncado ou fora do JSON,
 // ou recusam por limite de uso: tenta até 3 vezes antes de falhar a etapa.
 let lastError;
 for(let attempt=1;attempt<=3;attempt++){
  const res=await fetch('https://openrouter.ai/api/v1/chat/completions',{
   method:'POST',
   headers:{Authorization:`Bearer ${openRouterKey()}`,'Content-Type':'application/json','X-Title':'Sumula Online'},
   body:JSON.stringify({models,temperature,
    messages:[{role:'user',content:prompt+'\n\nResponda SOMENTE com um objeto JSON válido, sem markdown, que siga este JSON Schema:\n'+schemaText}]}),
   signal:AbortSignal.timeout(12*60000),
  });
  if(!res.ok){lastError=new Error(`Etapa ${name} falhou (OpenRouter HTTP ${res.status}).`);await new Promise(r=>setTimeout(r,15000*attempt));continue;}
  const json=await res.json();
  const raw=json?.choices?.[0]?.message?.content||'';
  try{
   const out=extractJson(raw,name);
   fs.writeFileSync(path.join(dir,name+'.json'),JSON.stringify({model:json?.model,attempt,out}));
   return out;
  }catch(e){
   lastError=e;
   fs.writeFileSync(path.join(dir,`${name}.${attempt}.raw.txt`),`${json?.model}\n${raw}`);
  }
 }
 throw lastError;
}
const schemaOf=(file)=>fs.readFileSync(path.join(ROOT,'editorial',file),'utf8');

// Páginas iniciais oficiais: candidatas de reserva quando o modelo não acerta URLs.
const SEEDS={
 volei:['https://www.cbv.com.br/','https://www.fivb.com/','https://en.volleyballworld.com/'],
 'volei-praia':['https://www.cbv.com.br/','https://en.volleyballworld.com/beachvolleyball/'],
 basquete:['https://www.cbb.com.br/','https://www.fiba.basketball/','https://lnb.com.br/'],
 futsal:['https://www.cbfs.com.br/','https://ligafutsal.com.br/'],
 futebol:['https://www.cbf.com.br/','https://www.theifab.com/','https://www.fifa.com/'],
 handebol:['https://www.cbhb.org.br/','https://www.ihf.info/'],
 'tenis-mesa':['https://www.cbtm.org.br/','https://www.ittf.com/'],
 badminton:['https://www.badminton.org.br/','https://bwfbadminton.com/'],
};
const decode=(t)=>t.replace(/&nbsp;/g,' ').replace(/&amp;/g,'&').replace(/&quot;/g,'"').replace(/&#0?39;|&apos;/g,"'").replace(/&#(\d+);/g,(_,n)=>String.fromCharCode(+n));
// Mesma regra do servidor (src/blog_validation.js#verifySources): só domínios
// permitidos, HTML, texto suficiente. Devolve o título real e um trecho do texto.
async function openSource(raw){
 let url=safeSource(raw);if(!url)return null;
 try{
  let r;
  for(let hop=0;hop<4;hop++){
   r=await fetch(url,{redirect:'manual',signal:AbortSignal.timeout(20000),headers:{'User-Agent':'SumulaOnline-Editorial/1.0 (+https://sumula.costaprojects.online/politica-editorial)'}});
   if(r.status>=300&&r.status<400){url=safeSource(new URL(r.headers.get('location')||'',url).href);if(!url)return null;continue;}
   break;
  }
  if(!r?.ok||!(r.headers.get('content-type')||'').includes('text/html'))return null;
  const html=(await r.text()).slice(0,3000000);
  const title=decode((html.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)/i)||html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)||[])[1]||'').replace(/\s+/g,' ').trim();
  const text=decode(html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi,' ').replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi,' ').replace(/<[^>]+>/g,' ')).replace(/\s+/g,' ').trim();
  if(text.length<300||title.length<8)return null;
  return {url,title:title.slice(0,200),publisher:new URL(url).hostname.replace(/^www\./,''),excerpt:text.slice(0,5000)};
 }catch{return null;}
}
async function research(dir,claim,focus){
 const pool=[],tried=new Set();
 const add=async(urls)=>{for(const u of urls){const k=safeSource(u);if(!k||tried.has(k)||pool.length>=5)continue;tried.add(k);const s=await openSource(k);if(s&&!pool.some(p=>p.url===s.url))pool.push(s);}};
 for(let round=0;round<2&&pool.length<4;round++){
  const out=await ask(dir,`scout${round}`,
   `Você ajuda o blog esportivo Súmula Online. Você NÃO tem acesso à web. Liste de 6 a 10 URLs https de páginas oficiais e estáveis (regras oficiais, regulamentos, páginas institucionais ou notícias) sobre a modalidade "${focus}" que você tem alta confiança de que existem, apenas nos domínios: ${DOMAINS.join(', ')}. Data de hoje: ${claim.day}. Evite temas já usados: ${JSON.stringify(claim.recent)}.`+
   (tried.size?`\nEstas URLs falharam ou já foram usadas, não repita: ${JSON.stringify([...tried])}`:''),
   '{"type":"object","required":["urls"],"properties":{"urls":{"type":"array","items":{"type":"string"}}}}',0.3);
  await add(Array.isArray(out.urls)?out.urls.slice(0,12):[]);
 }
 if(pool.length<2)await add(SEEDS[focus]||[]);
 if(pool.length<2)throw new Error(`Pesquisa: só ${pool.length} fonte(s) verificável(is) para ${focus}.`);
 return pool.map((s,i)=>({id:i+1,...s}));
}
const NO_WEB_WRITER=`

IMPORTANTE (sobrepõe as instruções de pesquisa acima): nesta execução você NÃO tem acesso à web. O sistema já abriu as fontes abaixo. Use SOMENTE estas fontes, com id, url, title e publisher exatamente como fornecidos, e SOMENTE fatos esportivos que aparecem nos trechos. O que não estiver nos trechos deve ser escrito como orientação editorial geral, sem números, datas, nomes ou regras específicas. Use kind "guide", salvo se um trecho trouxer notícia datada dos últimos sete dias. Deixe publishedAt vazio se a data não aparecer no trecho. Sobre a Súmula Online, cite SOMENTE os recursos da lista "Fatos do produto"; não descreva nenhuma outra função (nada de notificações, agendamento, exportação CSV, desafio de vídeo, alertas ou configurações não listadas).
Fontes verificadas:
`;
const NO_WEB_REVIEWER=`

IMPORTANTE (sobrepõe as instruções de navegação acima): nesta execução você NÃO tem acesso à web. O sistema já abriu cada fonte citada e confirmou que a página existe e que o título corresponde; os trechos estão abaixo. Confira o artigo SOMENTE contra estes trechos e contra os fatos do produto listados acima, que estão corretos e NÃO precisam aparecer nas fontes (presets do sistema, como sets de 25 com decisivo a 15, e os limites do plano gratuito são configurações do produto, não regras citadas). Reprove apenas: afirmação esportiva específica (número, data, nome, resultado, regra) que contradiz os trechos ou não tem suporte neles, contradição interna, categoria errada, regra de um esporte atribuída a outro, cópia ou publicidade excessiva. Não reprove com base na sua memória sobre regras quando o artigo segue os trechos. Orientações editoriais gerais não precisam de fonte.
REPROVE SEMPRE qualquer recurso, função ou integração da Súmula Online que não esteja literalmente na lista de fatos do produto acima (exemplos que NÃO existem: notificações ou e-mails automáticos, agendamento de horários, exportação CSV, desafio de vídeo, tempo técnico, altura da rede, alerta de posição irregular, histórico de substituições, configuração de líbero). Cite cada recurso inventado como um problema.
Trechos das fontes:
`;
async function main(){
 if(process.argv.includes('--status')){console.log(JSON.stringify(cli('status'),null,2));return;}
 const claim=cli('claim',null,process.argv.includes('--force')?['--force']:[]);
 if(claim.skip){console.log(JSON.stringify({time:new Date().toISOString(),...claim}));return;}
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'sumula-editorial-'));fs.chmodSync(dir,0o700);
 try{
  const focus=claim.focus||'volei';
  const context=`\n\nData editorial em Brasília: ${claim.day}. Modalidade-foco de hoje (use exatamente este valor em "category", salvo se só houver conteúdo oficial relevante em outra modalidade do sistema): ${focus}. Não invente acontecimentos. Evite pautas, palavras-chave principais e fontes já usadas:\n${JSON.stringify(claim.recent)}\n`;
  const candidateIndex=process.argv.indexOf('--candidate');
  let post,pool;
  if(candidateIndex>=0){
   post=JSON.parse(fs.readFileSync(process.argv[candidateIndex+1],'utf8'));pool=[];
   for(const s of post.sources||[]){const o=await openSource(s.url);if(o)pool.push({id:s.id,...o});}
  }else{
   pool=await research(dir,claim,focus);
   post=await ask(dir,'writer',fs.readFileSync(path.join(ROOT,'editorial/writer.md'),'utf8')+context+NO_WEB_WRITER+JSON.stringify(pool),schemaOf('post.schema.json'),0.5);
   // Garante que as fontes do artigo são exatamente as verificadas (URL e título reais).
   const byUrl=new Map(pool.map(s=>[s.url,s]));
   post.sources=(post.sources||[]).map(s=>byUrl.get(safeSource(s.url))||pool.find(p=>p.id===s.id)).filter(Boolean)
    .filter((s,i,a)=>a.findIndex(x=>x.url===s.url)===i).map(s=>({id:s.id,url:s.url,title:s.title,publisher:s.publisher,publishedAt:''}));
   // Sem data verificada nas fontes, o artigo é sempre um guia (news exige fonte recente datada).
   post.kind="guide";
   const ids=new Set(post.sources.map(s=>s.id));
   for(const sec of post.sections||[])sec.sourceIds=(sec.sourceIds||[]).filter(id=>ids.has(id));
  }
  validatePost(post);
  const excerpts=pool.filter(s=>post.sources.some(p=>p.url===s.url)).map(({id,url,title,excerpt})=>({id,url,title,excerpt}));
  const reviewer=fs.readFileSync(path.join(ROOT,'editorial/reviewer.md'),'utf8')+NO_WEB_REVIEWER+JSON.stringify(excerpts)+`\nData editorial: ${claim.day}.\nArtigo a conferir:\n`;
  // Revisão com até 2 rodadas de correção: o escritor recebe os problemas
  // apontados e reescreve só o necessário, mantendo as mesmas fontes.
  let review;
  for(let round=0;;round++){
   review=await ask(dir,`review${round}`,reviewer+JSON.stringify(post),schemaOf('review.schema.json'),0.1);
   const ok=review.approved===true&&Array.isArray(review.issues)&&!review.issues.length;
   if(ok||round>=2||candidateIndex>=0)break;
   const fixed=await ask(dir,`revise${round}`,
    `Você é o editor do blog Súmula Online. O revisor factual apontou os problemas abaixo no artigo JSON. Corrija TODOS: remova ou reescreva como orientação editorial geral (sem números, regras, datas ou nomes específicos) qualquer afirmação esportiva que não esteja nos trechos das fontes; os fatos do produto podem continuar, mas apresente-os claramente como configurações da Súmula Online, não como regras oficiais; remova qualquer recurso do produto que não esteja na lista de fatos do produto (placar e acompanhamento público, escalação, atletas por time, impressão/PDF, rodízio no vôlei de quadra, campeonatos com tabela/classificação/eliminatórias, cadastro de atletas e equipes, presets por modalidade e plano gratuito). Mantenha a mesma estrutura, slug, categoria, tipo e fontes (mesmos id, url, title e publisher), entre 650 e 900 palavras, em português do Brasil.\nProblemas:\n${JSON.stringify(review.issues)}\nTrechos das fontes:\n${JSON.stringify(excerpts)}\nArtigo:\n${JSON.stringify(post)}`,
    schemaOf('post.schema.json'),0.3);
   fixed.sources=post.sources;fixed.kind=post.kind;fixed.slug=post.slug;fixed.category=post.category;
   const ids=new Set(post.sources.map(s=>s.id));
   (fixed.sections||[]).forEach((sec,i)=>{
    sec.sourceIds=(sec.sourceIds||[]).filter(id=>ids.has(id));
    // O modelo costuma apagar as referências ao reescrever; recupera as da seção original.
    if(!sec.sourceIds.length&&post.sections?.[i]?.sourceIds?.length)sec.sourceIds=[...post.sections[i].sourceIds];
   });
   // Se a correção não for válida, a tentativa falha: nunca revisar de novo o
   // rascunho já recusado (outro modelo poderia aprová-lo por engano).
   try{validatePost(fixed);}catch(e){throw new Error(`Correção editorial inválida (${e.message}) após: `+review.issues.join(' ').slice(0,300));}
   post=fixed;
  }
  if(review.approved!==true||!Array.isArray(review.issues)||review.issues.length)throw new Error('Revisão editorial recusada: '+(review.issues||[]).join(' ').slice(0,450));
  const result=cli('publish',{day:claim.day,token:claim.token,post});
  console.log(JSON.stringify({time:new Date().toISOString(),published:true,...result}));
 }catch(e){
  const message=String(e.message).replace(/(?:sk|rk)_(?:live|test)_[A-Za-z0-9]+/g,'[credencial omitida]').slice(0,600);
  cli('fail',{day:claim.day,token:claim.token,error:message});throw new Error(message);
 }finally{if(process.env.SUMULA_KEEP_DIR)console.error('dir:',dir);else fs.rmSync(dir,{recursive:true,force:true});}
}
main().catch(e=>{console.error(new Date().toISOString(),e.message);process.exitCode=1;});
