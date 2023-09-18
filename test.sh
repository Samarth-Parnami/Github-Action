import gulp from 'gulp';
import clean from 'gulp-clean';
import cleanCSS from 'gulp-clean-css';
import concat from 'gulp-concat';
import minify from 'gulp-minify';
import {stream as critical} from 'critical';
import {XMLHttpRequest} from  "xmlhttprequest";
import nunjucksRender from 'gulp-nunjucks-render';
import environments from 'gulp-environments';
import gulpSequence from 'gulp-sequence';
import rename from 'gulp-rename';
import imagemin from 'gulp-imagemin';
import gulpPngquant from 'gulp-pngquant';
import newer from 'gulp-newer';
import replace from 'gulp-string-replace';
import shell from 'gulp-shell'
import {execSync} from 'child_process'
// import faqJsonBuyQr from './src/assets/buy-qr-faq-data.json';
import faqJson from './src/assets/qrcg-faq-data.json'  assert { type: "json" };
var development = environments.development;
var production = environments.production;
var staging = environments.make("staging");

var COMPILE = {
    SRC: ['src/**/*.html', 'src/**/*.php'],
    DEST: 'webroot'
};

const limitValue = 10;
let reviews = {};
let reviewsUptoLimitValue = {};
let jsonSchema = {};
let faqJsonSchema = {};
let faqJsonSchemaBuyQr = {};

let product_Data = [];

const storeFrontUrl = production() ? "https://storefrontapi.beaconstac.com/v1" : "https://storefrontapiqa.beaconstac.com/v1";
const includeGA = production() ? "true" : "false";
const worldMapDataUrl = production() ? "https://d1bqobzsowu5wu.cloudfront.net/analytics/qr-map.json" : "https://beaconstac-content-qa.s3.amazonaws.com/analytics/qr-map.json";
const qrScansDataUrl = production() ? "https://d1bqobzsowu5wu.cloudfront.net/analytics/analytics.json" : "https://beaconstac-content-qa.s3.amazonaws.com/analytics/analytics.json";
const amplitudeApiKey = production() ? "ad99af175f39d509b340cb95fab60c35" : "211221971a0c7ea8d9bbdcf35af392d7";
const gtmApiKey = production() ? "GTM-NMLR4W2" : "GTM-TJGQZ2T";

const whatsNewBlogURL = "https://bstacwhatsnew.wpengine.com/wp-json/wp/v2/";
const auth0Domain = production() ? "auth.beaconstac.com" : "authqa.beaconstac.com";
const auth0ClientId = production() ? "XC7sPXtSZdU1EDFwoGh31wr8N1qpej33" : "VFM1KKS9mazcMApLHWKMNnHeaGJedHHp";
const auth0Audience = production() ? "https://storefrontapi.beaconstac.com" : "https://storefrontapiqa.beaconstac.com";
const auth0Realm = production() ? "beaconstac-db" : "bac-qa-db";
const frontendCredentials = process.env.FRONTEND_USER + ":" + process.env.FRONTEND_PASSWORD;
const storeCredentials = process.env.STORE_USER + ":" + process.env.STORE_PASSWORD;
const currEnvironment = production() ? "production" : (staging() ? "staging" : "dev");
const jwtToken = process.env.JWT_STORE_SECRET;

var manageEnvironment = function (env) {
    const assetSource = production() ? "https://static.beaconstac.com" : (staging() ? "https://storage.googleapis.com/static-qa-beaconstac" : "");
    const dashboardUrl = production() ? "https://dashboard.beaconstac.com" : "https://bac-qa.firebaseapp.com";
    const stripeToken = production() ? "pk_WKgdkQCyGFmsrbo2ECwWE7HrxmMhm" : "pk_uoqHrPopXk3w70jKO3bXvxQRSrUfm";
    const google_oauth_client_id = production() || staging() ? "994582628215-b5tpc0n1fthnhvgm4ch7blaohknk9c8k.apps.googleusercontent.com" : "555348158880-aukdbetpvj4bkguis4tq2olg0kc9qfjv.apps.googleusercontent.com";
    const hardwareSKU = {
        outdoor: "WBKN",
        indoor: "BKN",
        pocket: "IBKN",
        longRange: "LBKN",
        keychain: "CBKN",
        usb: "UBKN",
        sticker: "NFC-STICKER",
        keycard: "NFC-CARD"
    };
    const intercomAppID = production() ? "hc4as48h" : "zpqzij6r";
    env.addGlobal('ASSETS_PATH', assetSource);
    env.addGlobal('STOREFRONT_URL', storeFrontUrl);
    env.addGlobal('DASHBOARD_URL', dashboardUrl);
    env.addGlobal('INCLUDE_GA', includeGA);
    env.addGlobal('STRIPE_TOKEN', stripeToken);
    env.addGlobal('HARDWARE_SKU', JSON.stringify(hardwareSKU));
    env.addGlobal('BUYBEACONS_URL', "/buy-beacons/");
    env.addGlobal('STORE_URL', "/store");
    env.addGlobal('INTERCOM_APP_ID', intercomAppID);
    // Upgrade the assets version by +0.01 whenever there is a change in JS
    env.addGlobal('ASSETS_VERSION', '1.65');
    env.addGlobal('QRCG_REVIEWER_DATA', JSON.stringify(reviewsUptoLimitValue));
    env.addGlobal('QRCG_RATING_SCHEMA', JSON.stringify(jsonSchema));
    
    env.addGlobal('QRCG_FAQ_SCHEMA', JSON.stringify(faqJsonSchema));
    env.addGlobal('BUY_QR_FAQ_SCHEMA', JSON.stringify(faqJsonSchemaBuyQr));

    env.addGlobal('WORLD_MAP_DATA_URL', worldMapDataUrl);
    env.addGlobal('QR_SCANS_DATA_URL', qrScansDataUrl);
    env.addGlobal('AMPLITUDE_API_KEY', amplitudeApiKey);
    env.addGlobal('GTM_API_KEY', gtmApiKey);
    env.addGlobal('WHATS_NEW_BLOG', whatsNewBlogURL);
    env.addGlobal('PRODUCT_DATA', JSON.stringify(product_Data));
    env.addGlobal('AUTH0_DOMAIN', auth0Domain);
    env.addGlobal('AUTH0_CLIENT_ID', auth0ClientId);
    env.addGlobal('AUTH0_AUDIENCE', auth0Audience);
    env.addGlobal('AUTH0_REALM', auth0Realm);
    env.addGlobal('STORE_CREDENTIALS', storeCredentials);
    env.addGlobal('FRONTEND_CREDENTIALS', frontendCredentials);
    env.addGlobal('CUSTOMER_COUNT', '30,000');
    env.addGlobal('CUSTOMER_COUNT_QRCG', '30000');
    env.addGlobal('DBC_COUNT', '55,000');
    env.addGlobal('SCAN_COUNT', '204 Million');
    env.addGlobal('CUSTOMER_COUNT_ES', '30.000');
    env.addGlobal('SCAN_COUNT_ES', '204 millones');
    env.addGlobal('G2_RATING', '4.95/5');
    env.addGlobal('JWT_TOKEN', jwtToken);
    env.addGlobal('ENVIRONMENT', currEnvironment);
    env.addGlobal('IS_ES', false);
    env.addGlobal('GOOGLE_OAUTH_CLIENT_ID',google_oauth_client_id);
    env.addGlobal('G2_BEST_RELATIONSHIP', '/assets/img/g2-logos-2023/g2-best-relationship.png');
    env.addGlobal('G2_BEST_USABILITY', '/assets/img/g2-logos-2023/g2-best-usability.png');
    env.addGlobal('G2_EASIEST_ADMIN', '/assets/img/g2-logos-2023/g2-easiest-admin.png');
    env.addGlobal('G2_EASIEST_TO_USE', '/assets/img/g2-logos-2023/g2-easiest-to-use.png');
    env.addGlobal('G2_LEADER_SM_BUSINESS', '/assets/img/g2-logos-2023/g2-leader-sm-business.png');
    env.addGlobal('G2_LEADER', '/assets/img/g2-logos-2023/g2-leader.png');
    env.addGlobal('G2_MEETS_REQUIREMENT', '/assets/img/g2-logos-2023/g2-meets-requirements.png');
    
    env.addFilter('getPageNameForBreadcrumb', function (url) {
        if (url) {
            if (url.substr(-1) == "/") {
                url = url.slice(0, -1);
            }
            return capitalizeFirstLetter(url.split('/').pop().split('#')[0].split('?')[0].replace(new RegExp("-", 'g'), " "));
        }
        return "";
    })
};

function capitalizeFirstLetter(string) {
    string = string.replace("qr code", "QR Code");
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function fetchQRCGReviewsFromDatastore() {
    return new Promise((resolve, reject) => {
        let xhr = new XMLHttpRequest();
        xhr.addEventListener("readystatechange", function () {
            if (this.readyState === 4) {
                if (this.status === 200) {
                    resolve(JSON.parse(this.responseText));
                } else {
                    reject(this.status + " Error fetching review data");
                }
            }
        });
        xhr.open('GET', storeFrontUrl + '/qrcgreviews/', true);
        xhr.setRequestHeader("Authorization", "Basic " + Buffer.from(frontendCredentials, 'binary').toString('base64'));
        xhr.setRequestHeader('content-type', 'application/json;charset=UTF-8');
        xhr.send();
    });
}

function reduceReviewstoLimitValue(reviews) {
    return new Promise((resolve, reject) => {
        let reviewsWithUpperBound = [];
        for (let i = 0; i < limitValue; i++) {
            reviewsWithUpperBound.push(reviews[i]);
        }
        resolve(reviewsWithUpperBound);
    });
}

function createQRCGFAQSchema(faqContent) {
    return new Promise((resolve, reject) => {
        let baseSchema = {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": []
        };

        for (let i = 0; i < faqContent.length; i++) {
            let dynamicFAQ = {};
            dynamicFAQ.acceptedAnswer = {};
            dynamicFAQ['@type'] = "Question";
            dynamicFAQ['name'] = faqContent[i].question;
            dynamicFAQ['acceptedAnswer']['@type'] = "Answer";
            dynamicFAQ['acceptedAnswer']['text'] = faqContent[i].answer;
            baseSchema['mainEntity'].push(dynamicFAQ);
        }
        resolve(baseSchema);
    });
}

function createQRCGJSONSchema(reviewers, allReviewers) {
    return new Promise((resolve, reject) => {
        let reviewArray = [];
        let totalStar = 0;

        let baseSchema = {
            "@context": "https://schema.org/",
            "@type": "Product",
            "name": "QR Code Generator",
            "image": "https://static.beaconstac.com/assets/img/qr-code-generator-create-customize-campaigns.png",
            "description": "Create free custom QR Codes with logo to engage with customers",
            "brand": "Beaconstac",
            "mpn": "SFT-QRCG",
            "sku": "SFT-QRCG",
            "offers": {
                "@type": "Offer",
                "url": "https://www.beaconstac.com/qr-code-generator",
                "priceCurrency": "USD",
                "price": "0",
                "priceValidUntil": "2023-08-31",
                "availability": "https://schema.org/InStock"
            },
            "aggregateRating": {
                "@type": "AggregateRating",
                "ratingValue": "",
                "bestRating": "5",
                "worstRating": "1",
                "ratingCount": "",
                "reviewCount": ""
            }
        };

        for (let i = 0; i < reviewers.length; i++) {
            let dynamicReview = {};
            dynamicReview.publisher = {};
            dynamicReview.author = {};
            dynamicReview.reviewRating = {};
            dynamicReview['@type'] = "review";
            const date = new Date(reviewers[i]['posted_at']);
            const checkMonth = (date.getMonth() + 1) < 10 ? '-0' : '-';
            dynamicReview['datePublished'] = date.getFullYear() + checkMonth + (date.getMonth() + 1) + '-' + date.getDate();
            dynamicReview['name'] = reviewers[i]['review_title'];
            dynamicReview['reviewBody'] = reviewers[i]['review'];
            dynamicReview['publisher']['@type'] = "Organization";
            dynamicReview['publisher']['name'] = "Beaconstac";
            dynamicReview['author']['@type'] = "Person";
            dynamicReview['author']['name'] = reviewers[i]['name'];
            dynamicReview['reviewRating']['@type'] = 'Rating';
            dynamicReview['reviewRating']['bestRating'] = '5';
            dynamicReview['reviewRating']['worstRating'] = '1';
            dynamicReview['reviewRating']['ratingValue'] = reviewers[i]['rating'];
            reviewArray.push(dynamicReview);
        }

        for (let i = 0; i < allReviewers.length; i++) {
            totalStar += parseInt(allReviewers[i]['rating']);
        }

        const avgRating = totalStar / (allReviewers.length);
        baseSchema['aggregateRating']['ratingValue'] = avgRating.toString();
        baseSchema['aggregateRating']['ratingCount'] = allReviewers.length.toString();
        baseSchema['aggregateRating']['reviewCount'] = allReviewers.length.toString();
        baseSchema['review'] = reviewArray;
        resolve(baseSchema);
    })
}

//fetch prodect details
function fetchProductDetails() {
    return new Promise((resolve, reject) => {
        let xhr = new XMLHttpRequest();
        xhr.addEventListener("readystatechange", function () {
            if (this.readyState === 4) {
                if (this.status === 200) {
                    resolve(JSON.parse(this.responseText));
                } else {
                    reject(this.status + " Error fetching product data");
                }
            }
        });
        xhr.open('GET', storeFrontUrl + '/products/', true);
        xhr.setRequestHeader("Authorization", "Basic " + Buffer.from(frontendCredentials, 'binary').toString('base64'));
        xhr.setRequestHeader('content-type', 'application/json;charset=UTF-8');
        xhr.send();
    });
}

gulp.task('render', async function () {
    try {
        reviews = await fetchQRCGReviewsFromDatastore();
        reviewsUptoLimitValue = await reduceReviewstoLimitValue(reviews.data);
        reviewsUptoLimitValue = JSON.parse(JSON.stringify(reviewsUptoLimitValue).replace(/'/g, '&apos;'));
        jsonSchema = await createQRCGJSONSchema(reviewsUptoLimitValue, reviews.data);

        faqJsonSchema = await createQRCGFAQSchema(faqJson);
        faqJsonSchemaBuyQr = await createQRCGFAQSchema(faqJson);
        // product_Data = await fetchProductDetails();
        // product_Data = JSON.parse(JSON.stringify(product_Data).replace(/'/g, '&apos;'));
    } catch (e) {
        await Promise.reject(new Error(e));
    }
    return gulp.src(COMPILE.SRC)
        .pipe(nunjucksRender({
            path: ['src', 'src/layouts','src/qrcg/qrcg-widget-new.js','src/qrcg/qrcg-widget-new.html'],
            inheritExtension: true,
            manageEnv: manageEnvironment
        }))
        .pipe(gulp.dest(COMPILE.DEST));
});

gulp.task('assets', async function () {
    //gulp.src(['src/assets/**/*']).pipe(gulp.dest('webroot/assets'));
    //exclude image files.
    gulp.src(['src/assets/**/*', '!src/assets/**/*.{jpg,jpeg,png,svg,gif,mp4,js}', '!src/assets/webfonts/**/*'])
        .pipe(replace(new RegExp('{{FRONTEND_CREDENTIALS}}', 'g'), frontendCredentials))
        .pipe(gulp.dest('webroot/assets'));
    gulp.src(['src/assets/webfonts/**/*']).pipe(gulp.dest('webroot/assets/webfonts'));
    gulp.src(['src/assets/**/*.mp4']).pipe(gulp.dest('webroot/assets/'));
    gulp.src(['src/*.xml']).pipe(gulp.dest('webroot'));
    gulp.src(['src/**/*.txt']).pipe(gulp.dest('webroot'));
    gulp.src(['src/*.ico']).pipe(gulp.dest('webroot'));
    gulp.src(['src/*.pdf']).pipe(gulp.dest('webroot'));
    gulp.src(['src/.well-known/microsoft-identity-association.json']).pipe(gulp.dest('webroot/.well-known/'));
});

gulp.task('watch', function () {
    gulp.watch(COMPILE.SRC, gulp.series('render'));
    gulp.watch('src/layouts/*.nunjucks', gulp.series('render'));
    gulp.watch('src/es/layouts/*.nunjucks', gulp.series('render'));
    gulp.watch('src/es/partials/*.nunjucks', gulp.series('render'));
    gulp.watch('src/partials/*.nunjucks', gulp.series('render'));
    gulp.watch('src/partials/**/*.nunjucks', gulp.series('render'));
    gulp.watch('src/macros/**/*.njk', gulp.series('render'));
    gulp.watch('src/assets/**/*', gulp.series('assets'));
    gulp.watch('src/*.xml', gulp.series('assets'));
    gulp.watch('src/*.txt', gulp.series('assets'));
    gulp.watch('src/*.html', gulp.series('assets'));
    gulp.watch('src/assets/img/**/*.png', gulp.series('compress-png'));
    gulp.watch('src/assets/img/**/*.{jpeg,jpg,svg,gif,webp}', gulp.series('compress-images'));
    gulp.watch('src/assets/*.js', gulp.series('render'));
});


gulp.task('minify-css', function () {
    return gulp.src('webroot/assets/**/*.css')
        .pipe(cleanCSS({compatibility: 'ie8'}))
        .pipe(gulp.dest('webroot/assets/'));
});

gulp.task('combine-css', function () {
    return gulp.src(['src/assets/css/all.min.css', 'src/assets/css/toolkit-startup.min.css',
        'src/assets/css/beaconstac.css', 'src/assets/css/store.css',
        'src/assets/css/utilities.css'])
        .pipe(concat('style.min.css'))
        .pipe(gulp.dest('webroot/assets/css'))
});

gulp.task('minify-js', function () {
    return gulp.src('src/assets/js/**/*.js')
        .pipe(minify({
            ignoreFiles: ['*.min.js'],
            noSource: true,
            ext: {min: '.js'}
        }))
        .pipe(replace(new RegExp('{{FRONTEND_CREDENTIALS}}', 'g'), frontendCredentials))
        .pipe(gulp.dest('webroot/assets/js'))
});

// Generate & Inline Critical-path CSS on all .html files
gulp.task('critical-css', function () {
    return gulp.src(['webroot/**/*.html'])
        .pipe(critical({
            base: 'webroot/',
            css: [
                'webroot/assets/css/style.min.css'
            ],
            inline: true,
            penthouse: {
                timeout: 200000
            }
        }))
        .on('error', err => {
            console.log(err.message);
        })
        .pipe(gulp.dest('webroot/'));
});

//Generate robot.txt based on environment
gulp.task('generate-robot.txt', function () {
    const fileSource = production() ? "src/assets/production-robot.txt" : "src/assets/staging-robot.txt";
    return gulp.src(fileSource)
        .pipe(rename('robots.txt'))
        .pipe(gulp.dest('webroot/'))
});

// Minify any new non-png images
gulp.task('compress-images', function () {
    // Add the newer pipe to pass through newer images only
    return gulp.src(['src/assets/img/**/*.{jpeg,jpg,svg,gif,webp}'])
        .pipe(newer('webroot/assets/img/'))
        .pipe(imagemin([
            imagemin.gifsicle({interlaced: false}),
            imagemin.mozjpeg({quality: 75, progressive: true}),
            //imagemin.optipng({optimizationLevel: 5}),
            imagemin.svgo({
                plugins: [
                    {removeViewBox: true},
                    {cleanupIDs: false}
                ]
            })
        ]))
        .pipe(gulp.dest('webroot/assets/img'));
});

// Minify any new png images
gulp.task('compress-png', function () {
    // Add the newer pipe to pass through newer images only
    return gulp.src(['src/assets/img/**/*.png'])
        .pipe(newer('webroot/assets/img/'))
        .pipe(gulpPngquant({
            quality: '50-80', 
        }))
        .pipe(gulp.dest('webroot/assets/img'));
});

//compress only new or modified img files
function getGitChangedImages() {

    const untrackedOutput = execSync('git ls-files --others --exclude-standard').toString();
    const currentBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
    const diffOutput = execSync(`git diff ${currentBranch}..develop --diff-filter=A --name-only`).toString();
    const output = untrackedOutput + diffOutput.split('\n').map(line => 'A\t' + line).join('\n');

    return output.split('\n')
    .map(line => line.trim())
    .filter(filePath => filePath.startsWith('src/assets/img/') && /\.(jpeg|jpg|svg|gif)$/.test(filePath));
}

function getGitChangedImagesPNG() {

    const untrackedOutput = execSync('git ls-files --others --exclude-standard').toString();
    const currentBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
    const diffOutput = execSync(`git diff ${currentBranch}..main --diff-filter=A --name-only`).toString();
    const output = untrackedOutput + diffOutput.split('\n').map(line => 'A\t' + line).join('\n');

    return output.split('\n')
    .map(line => line.trim())
    .filter(filePath => filePath.startsWith('src/assets/img/') && /\.(png)$/.test(filePath));
}

gulp.task('compress-new-images', function (done) {
    const gitChangedImages = getGitChangedImages();
    if (gitChangedImages.length === 0) {
        done();
        return;
    }
    return gulp.src(gitChangedImages)
    .pipe(imagemin([
        imagemin.gifsicle({interlaced: false}),
        imagemin.mozjpeg({quality: 75, progressive: true}),
        imagemin.svgo({
            plugins: [
                {removeViewBox: true},
                {cleanupIDs: false}
            ]
        })
    ]))
    .pipe(gulp.dest(file => file.base));
});

gulp.task('compress-new-images-png', function(done) {
    const gitChangedImages = getGitChangedImagesPNG();
    if (gitChangedImages.length === 0) {
        done();
        return;
    }
    return gulp.src(gitChangedImages)
    .pipe(gulpPngquant({
        quality: '50-80',
    }))
    .pipe(gulp.dest(file => file.base));
});

//copy statically build nextJs pages
gulp.task('next-files', async function () {
    gulp.src(['src-next/out/**/*']).pipe(gulp.dest('webroot'));
});

gulp.task('generate-webroot', function () {
    return gulp.src(['src/assets/img/**/*'])
      .pipe(newer('webroot/assets/img'))
      .pipe(gulp.dest('webroot/assets/img'));
  });
gulp.task('qrcg-widget', async function () {
    const assetPath = production() ? "https://static.beaconstac.com/" : (staging() ? "https://storage.googleapis.com/static-qa-beaconstac/" : "/");
    gulp.src('src/qrcg/*.js') 
        .pipe(replace('{{ ASSETS_PATH }}',assetPath))
        .pipe(replace('{{ STORE_URL }}','/store'))
        .pipe(replace('{{ CUSTOMER_COUNT }}','30,000'))
        .pipe(replace('{{ customQrcgWidget }}','QRCG'))
        .pipe(gulp.dest('webroot/qrcg'));
});

gulp.task('img-compress-git',gulp.series('compress-new-images','compress-new-images-png'));
gulp.task('sitemap-generation', shell.task('node src/automations/sitemap.js'));

gulp.task('deployment',gulp.series('render', 'assets' ,'qrcg-widget' ,'generate-robot.txt', 'combine-css', 'sitemap-generation'));

//gulp.task('dist', gulpSequence(['render', 'assets'], 'generate-robot.txt',['minify-css', 'minify-js'], 'combine-css', 'critical-css','compress-images','compress-png'));
gulp.task('dist', gulp.series('render', 'assets', 'qrcg-widget','generate-robot.txt','combine-css', 'compress-new-images','compress-new-images-png', 'generate-webroot', 'sitemap-generation'));
//gulp.task('dist', gulpSequence('render', 'assets', 'minify-css', 'minify-js', 'combine-css', 'critical-css'))
gulp.task('minify', gulp.series('minify-css', 'minify-js','critical-css'));
gulp.task('next', gulp.series('next-files'));
