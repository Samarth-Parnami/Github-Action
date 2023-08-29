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

gulp.task('minify-css', function () {
    return gulp.src('webroot/assets/**/*.css')
        .pipe(cleanCSS({compatibility: 'ie8'}))
        .pipe(gulp.dest('webroot/assets/'));
});

gulp.task('combine-css', function () {
    return gulp.src(['src/assets/css/font-awesome.min.css', 'src/assets/css/toolkit-startup.min.css',
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

    const modifiedOutput = execSync('git diff --name-only --diff-filter=A HEAD^').toString();
    const untrackedOutput = execSync('git ls-files --others --exclude-standard').toString();
    const currentBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
    const diffOutput = execSync(`git diff ${currentBranch}..develop`).toString();
    console.log(diffOutput);
    console.log(diffOutput.split('\n'));
    const output = modifiedOutput + untrackedOutput.split('\n').map(line => 'A\t' + line).join('\n');

    return output.split('\n')
    .map(line => line.trim())
    .filter(filePath => filePath.startsWith('src/assets/img/') && /\.(jpeg|jpg|svg|gif)$/.test(filePath));
}
function getGitChangedImagesPNG() {

    const modifiedOutput = execSync('git diff --name-only --diff-filter=A HEAD^').toString();  
    const untrackedOutput = execSync('git ls-files --others --exclude-standard').toString();
    const output = modifiedOutput + untrackedOutput.split('\n').map(line => 'A\t' + line).join('\n');

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

// gulp.task('img-compress-git',gulp.series('compress-new-images','compress-new-images-png'));
// gulp.task('sitemap-generation', shell.task('node src/automations/sitemap.js'));

// gulp.task('deployment',gulp.series('render', 'assets', 'generate-robot.txt', 'combine-css', 'sitemap-generation'));

// //gulp.task('dist', gulpSequence(['render', 'assets'], 'generate-robot.txt',['minify-css', 'minify-js'], 'combine-css', 'critical-css','compress-images','compress-png'));
// gulp.task('dist', gulp.series('render', 'assets', 'generate-robot.txt','combine-css', 'compress-new-images','compress-new-images-png', 'generate-webroot', 'sitemap-generation'));
// //gulp.task('dist', gulpSequence('render', 'assets', 'minify-css', 'minify-js', 'combine-css', 'critical-css'))
// gulp.task('minify', gulp.series('minify-css', 'minify-js','critical-css'));
// gulp.task('next', gulp.series('next-files'));
