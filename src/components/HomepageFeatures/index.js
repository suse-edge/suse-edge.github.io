import React from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Powered by Geekos',
    Svg: require('@site/static/img/SUSE_Logo-vert_L_Green-pos_sRGB.svg').default,
    description: (
      <>
        SUSE is an industry stalwart with more than 30 years of contributing to the Open Source community. We are ready to take your workloads to the Edge and beyond.
      </>
    ),
  },
  {
    title: 'Docusaurus',
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        We <b>shamelessly</b> use Docusaurus, an excellent open source project, to create our Documentation. The theme is very lightly tweaked to match our brand guidelines.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--6')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
